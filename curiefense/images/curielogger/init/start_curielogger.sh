#!/bin/bash

ES_PATTERN_PATH="api/saved_objects/index-pattern/curiefense"
ES_INDEX_NAME=${CURIEFENSE_ES_INDEX_NAME:-curieaccesslog}
CURLJS="curl --silent -H Content-Type:application/json --output /dev/null"
CURLCODE="curl --silent --write-out %{http_code}\n --output /dev/null"

wait_for_es () {
	curl --silent --output /dev/null -X GET "${ELASTICSEARCH_URL}_cluster/health?wait_for_status=yellow&timeout=60s"
}

define_es_lifecycle_policy () {
	if $CURLCODE "${ELASTICSEARCH_URL}_ilm/policy/curie_policy"|grep -qv 404; then
		echo "Elasticsearch lifecycle policy already exists."
	else
		$CURLJS -X PUT "${ELASTICSEARCH_URL}_ilm/policy/curie_policy" --data-binary @/init/es_lifecycle_policy.json
		echo "Elasticsearch lifecycle policy defined."
	fi
}

define_es_index () {
	if $CURLCODE "$ELASTICSEARCH_URL$ES_INDEX_NAME-000001"|grep -qv 404; then
		echo "Elastic index and alias already exists."
	else
		sed "s/INDEX_NAME/$ES_INDEX_NAME/" /init/es_index.json|$CURLJS -X PUT -d @- "$ELASTICSEARCH_URL$ES_INDEX_NAME-000001"
		echo "Elastic index and alias created."
	fi
}

define_es_mapping () {
	if $CURLCODE "$ELASTICSEARCH_URL$ES_INDEX_NAME"|grep -qv 404; then
		echo "Elasticsearch mapping already exists."
	else
		$CURLJS -XPUT "$ELASTICSEARCH_URL$ES_INDEX_NAME" --data-binary @/init/type_mapping.json
		echo "Elasticsearch mapping created."
	fi
}

create_kibana_index_pattern () {
	# Wait for kibana to become reachable
	while true; do
		if $CURLCODE "${CURIELOGGER_KIBANA_URL}api/status"|grep -q 200; then
			break
		fi
		echo "Kibana at $CURIELOGGER_KIBANA_URL is not reachable yet, waiting 5s..."
		sleep 5
	done

	# Check whether the index pattern already exists
	if $CURLCODE "$CURIELOGGER_KIBANA_URL$ES_PATTERN_PATH"|grep -qv 404; then
		# already exists
		echo "Kibana index already exists."
	else
		# Create the index pattern
		$CURLJS -X POST "$CURIELOGGER_KIBANA_URL$ES_PATTERN_PATH" -H 'kbn-xsrf: true' -d '{"attributes": {"title": "'"$ES_INDEX_NAME"'","timeFieldName": "@timestamp"}}'
		echo "Kibana index $ES_INDEX_NAME created."
	fi
}


if [ -n "$CURIELOGGER_INITIALIZE_KIBANA_INDEX" ]; then
	# in case logs are saved in elasticsearch and not postgres
	>&2 echo "Creating an index pattern in Kibana if needed."
	wait_for_es
	define_es_lifecycle_policy
	define_es_index
	define_es_mapping
	create_kibana_index_pattern
fi

/bin/curielogger
