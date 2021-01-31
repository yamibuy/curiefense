#! /bin/bash

###########################################################################
# this file downloads the last hour's 48th minute file from GS bucket     #
# of given planets. convert them into the ES format, plus adding          #
# the _bulk index line (2 lines per document).                            #
# split the output into a 20K lines each (50MB seems to be the threshold) #
# insert the split files into Elasticsearch                               #
###########################################################################

wd="/home/tzury/bqmigrate"

## pick last hour's 48's minute. e.g. 20210131T0548
timespamp=$(date -d "1 hour ago" "+%Y%m%dT%H48")

cd $wd

for planet in "$@";
do
    gsutil cp "gs://rbz-logs-$planet/bqinsert/queue-in/compose/$timespamp-bq_load00" "bq-json/$planet$timespamp-bq_load00";
done

for fi in bq-json/*-bq_load00;
do
    echo $fi;
    python3 utils/convert.py < $fi | split -l 20000 - "bq-json/$(basename $fi).split." -da 4;
done

for fi in bq-json/*.split.*;
do
    curl -s -H "Content-Type: application/x-ndjson" -XPOST localhost:9200/_bulk --data-binary "@$fi";
done

## cleanup
rm bq-json/*

