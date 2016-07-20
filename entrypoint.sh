#!/usr/bin/env bash

[ "$DEBUG" == 'true' ] && set -x

set -eo pipefail

curl -s -H "Authorization: $DOCKERCLOUD_AUTH" -H "Accept: application/json" $DOCKERCLOUD_SERVICE_API_URL

exec /docker-entrypoint.sh "$@"