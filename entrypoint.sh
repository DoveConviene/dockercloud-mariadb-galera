#!/usr/bin/env bash

[ "$DEBUG" == 'true' ] && set -x

set -eo pipefail


echo ">> Contacting DockerCloud Service API"
MARIADB_SERVICE_API_OUTPUT=$(curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL)
echo "${MARIADB_SERVICE_API_OUTPUT}"

RUNNING_NUM_CONTAINERS=$(echo "${MARIADB_SERVICE_API_OUTPUT}" | jq -r '.running_num_containers')
WSREP_CLUSTER_ADDRESS="gcomm://"

if [ "${RUNNING_NUM_CONTAINERS}" = 0 ]; then
	echo ">> Marvin: I'm alone. I'll try to bootstrap the cluster..."
	set -- "$@" --wsrep-new-cluster
fi

if [ "${RUNNING_NUM_CONTAINERS}" -gt 0 ]; then
	mkdir -p /var/lib/mysql/mysql && chown -R mysql:mysql /var/lib/mysql/mysql
	WSREP_CLUSTER_ADDRESS+=${DOCKERCLOUD_SERVICE_HOSTNAME}:4567
	echo "Marvin: I'm not alone. I'll try to join my buddies at ${WSREP_CLUSTER_ADDRESS}"
	set -- "$@" --wsrep-cluster-address="${WSREP_CLUSTER_ADDRESS}"
fi

echo '>> Generating Galera Config'
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
wsrep_cluster_name="${WSREP_CLUSTER_NAME:-42}"
wsrep_sst_auth="${WSREP_SST_AUTH}"
wsrep_sst_method="${WSREP_SST_METHOD:-rsync}"
EOF

if [ -n "$WSREP_NODE_ADDRESS" ]; then
	echo wsrep_node_address="${WSREP_NODE_ADDRESS}" >> /etc/mysql/conf.d/galera-auto-generated.cnf
fi

exec /docker-entrypoint.sh "$@"