#!/usr/bin/env bash

[ "$DEBUG" == 'true' ] && set -x

set -eo pipefail

echo ${DOCKERCLOUD_AUTH}