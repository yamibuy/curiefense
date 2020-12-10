FROM istio/proxyv2:1.5.1

COPY config /config
COPY envoy.yaml /etc/
COPY curiefense.wasm /lib

ENTRYPOINT ["/usr/local/bin/envoy", "-c", "/etc/envoy.yaml", "-l", "debug", "--service-cluster", "proxy"]
