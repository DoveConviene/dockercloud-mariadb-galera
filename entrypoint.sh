#!/usr/bin/env bash

[ "$DEBUG" == 'true' ] && set -x

set -eo pipefail

RUNNING_NUM_CONTAINERS=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL | jq -r '.running_num_containers')

WSREP_NODE_ADDRESS="gcomm://"

if [ "${RUNNING_NUM_CONTAINERS}" = 1 ]; then
	set -- "$@" --wsrep-new-cluster
fi

if [ "${RUNNING_NUM_CONTAINERS}" -gt 1 ]; then
	mkdir -p /var/lib/mysql/mysql && chown -R mysql:mysql /var/lib/mysql/mysql

	for container_url in $(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL | jq -r '.containers[]'); do
		for node_url in $(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" "$DOCKERCLOUD_REST_HOST$container_url"  | jq -r 'if .state == "Running" then .node else null end'); do
			WSREP_NODE_ADDRESS+=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" "$DOCKERCLOUD_REST_HOST$node_url" | jq -r '.public_ip')
			WSREP_NODE_ADDRESS+=","
		done
	done
fi

echo '>> Creating Galera Config'
export MYSQL_INITDB_SKIP_TZINFO="yes"
export MYSQL_ALLOW_EMPTY_PASSWORD="yes"

cat <<- EOF > /etc/mysql/conf.d/galera-auto-generated.cnf
# Galera Cluster Auto Generated Config
[server]
bind-address="0.0.0.0"
binlog_format="row"
default_storage_engine="InnoDB"
innodb_autoinc_lock_mode="2"
innodb_locks_unsafe_for_binlog="1"

[galera]
wsrep_on="on"
wsrep_provider="${WSREP_PROVIDER:-/usr/lib/libgalera_smm.so}"
wsrep_provider_options="${WSREP_PROVIDER_OPTIONS}"
wsrep_cluster_address="${WSREP_CLUSTER_ADDRESS}"
wsrep_cluster_name="${WSREP_CLUSTER_NAME:-my_wsrep_cluster}"
wsrep_sst_auth="${WSREP_SST_AUTH}"
wsrep_sst_method="${WSREP_SST_METHOD:-rsync}"
EOF

if [ -n "$WSREP_NODE_ADDRESS" ]; then
	echo wsrep_node_address="${WSREP_NODE_ADDRESS}" >> /etc/mysql/conf.d/galera-auto-generated.cnf
fi

exec /docker-entrypoint.sh "$@"