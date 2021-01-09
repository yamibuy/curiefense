#!/bin/bash

create_index () {
	PATTERN_PATH="api/saved_objects/index-pattern/curiefense"
	# Wait for kibana to become reachable
	while true; do
		if curl --write-out "%{http_code}\n" --output /dev/null --silent "${CURIELOGGER_KIBANA_HOST}:5601/api/status"|grep -q 200; then
			break
		fi
		sleep 5
		RETRIES=$((RETRIES+1))
	done

	# Check whether the index pattern already exists
	if curl  --write-out '%{http_code}\n' --output /dev/null --silent "http://$CURIELOGGER_KIBANA_HOST:5601/$PATTERN_PATH"|grep -qv 404; then
		# already exists
		exit 0
	fi

	# Create the index pattern
	curl --silent -X POST "http://$CURIELOGGER_KIBANA_HOST:5601/$PATTERN_PATH" -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -d '{"attributes": {"title": "logstash-*","timeFieldName": "@timestamp"}}'
}

if [ -n "$CURIELOGGER_KIBANA_HOST" ]; then
	# in case logs are saved in elasticsearch and not postgres
	>&2 echo "Creating an index pattern in Kibana if needed."
	create_index
fi

/bin/curielogger
