#!/usr/bin/env python3
import requests
import socket
import ssl
from urllib.parse import urlparse
from requests_toolbelt.utils import dump
import asyncio


# async def gather_with_concurrency(n, *tasks):
#     # https://stackoverflow.com/questions/48483348/how-to-limit-concurrency-with-python-asyncio/61478547#61478547
#     semaphore = asyncio.Semaphore(n)

#     async def sem_task(task):
#         async with semaphore:
#             return await task
#     return await asyncio.gather(*(sem_task(task) for task in tasks))


async def raw_send(hostname, port, contents, tls=False):
    if tls:
        context = ssl.SSLContext()
        context.verify_mode = ssl.CERT_NONE
        reader, writer = await asyncio.open_connection(hostname, port, ssl=context)
    else:
        reader, writer = await asyncio.open_connection(hostname, port)
    writer.write(contents)
    await writer.drain()
    writer.close()


async def bitflip_send(resp):
    data = dump.dump_response(resp, request_prefix=b'<<<')
    req = b'\n'.join([l[3:] for l in data.splitlines() if l.startswith(b'<<<')]) + b'\n'
    purl = urlparse(resp.url)
    hostname, port = purl.hostname, purl.port
    if port is None:
        if purl.scheme == 'http':
            port = 80
        elif purl.scheme == 'https':
            port = 443
    if port in (80, 30081):
        tls = False
    else:
        tls = True
    tasks = []
    for idx in range(len(req)):
        for bit in range(8):
            mask = 1 << bit
            flipped_req = req[:idx] + bytes([req[idx] ^ mask]) + req[idx+1:]
            tasks.append(raw_send(hostname, port, flipped_req, tls))
    i = 0
    while i < len(tasks):
        await asyncio.gather(*tasks[i:i+100])
        i += 100
        import time
        time.sleep(5)


if __name__ == '__main__':
    resp = requests.get("https://192.168.49.2:30081/", verify=False)
    asyncio.run(bitflip_send(resp))

