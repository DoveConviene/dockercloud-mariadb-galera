#!/usr/bin/env bash

[ "$DEBUG" == 'true' ] && set -x

set -eo pipefail

RUNNING_NUM_CONTAINERS=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL | jq -r '.running_num_containers')

CLUSTER_ADDRESS="gcomm://"

if [ "${RUNNING_NUM_CONTAINERS}" = 1 ]; then
	set -- "$@" --wsrep-cluster-address=$CLUSTER_ADDRESS
fi

if [ "${RUNNING_NUM_CONTAINERS}" -gt 1]; then
	for container_url in $(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL | jq -r '.containers[]'); do
		for node_url in $(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" "$DOCKERCLOUD_REST_HOST$container_url"  | jq -r 'if .state == "Running" then .node else null end'); do
			CLUSTER_ADDRESS+=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" "$DOCKERCLOUD_REST_HOST$node_url" | jq -r '.public_ip')
			CLUSTER_ADDRESS+=","
		done
	done

	set -- "$@" --wsrep-cluster-address=$CLUSTER_ADDRESS
fi

exec /docker-entrypoint.sh "$@"