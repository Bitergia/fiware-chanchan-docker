#!/bin/bash
set -e

source /entrypoint-common.sh

check_var MONGODB_HOSTNAME mongodb
check_var MONGODB_PORT 27017
check_var ORION_PORT 1026

# fix variables when using docker-compose
if [[ ${MONGODB_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export MONGODB_PORT=${BASH_REMATCH[1]}
fi

if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export ORION_PORT=${BASH_REMATCH[1]}
fi

check_host_port ${MONGODB_HOSTNAME} ${MONGODB_PORT}

# configure orion
sed -i /etc/sysconfig/contextBroker \
    -e "s/^BROKER_DATABASE_HOST=.*/BROKER_DATABASE_HOST=${MONGODB_HOSTNAME}/g" \
    -e "s/^BROKER_PORT=.*/BROKER_PORT=${ORION_PORT}/g"

exec /sbin/init
