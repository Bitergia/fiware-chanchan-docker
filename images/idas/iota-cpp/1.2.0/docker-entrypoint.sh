#!/bin/bash
set -e

source /entrypoint-common.sh

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    check_var MONGODB_HOSTNAME mongodb
    check_var MONGODB_PORT 27017
    check_var MONGODB_DATABASE iota-cpp
    check_var ORION_HOSTNAME orion
    check_var ORION_PORT 1026
    check_var IOTA_PATH /etc/iot

    # fix variables when using docker-compose
    if [[ ${MONGODB_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
        export MONGODB_PORT=${BASH_REMATCH[1]}
    fi

    if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
        export ORION_PORT=${BASH_REMATCH[1]}
    fi

    check_host_port ${MONGODB_HOSTNAME} ${MONGODB_PORT}
    check_host_port ${ORION_HOSTNAME} ${ORION_PORT}

    echo "Testing if orion is ready at http://${ORION_HOSTNAME}:${ORION_PORT}/version"

    check_url http://${ORION_HOSTNAME}:${ORION_PORT}/version "<version>.*</version>"

    # configure iotagent
    sed -i ${IOTA_PATH}/config.json \
        -e "s|MONGODB_HOSTNAME|${MONGODB_HOSTNAME}|g" \
        -e "s|MONGODB_PORT|${MONGODB_PORT}|g" \
        -e "s|MONGODB_DATABASE|${MONGODB_DATABASE}|g" \
        -e "s|ORION_HOSTNAME|${ORION_HOSTNAME}|g" \
        -e "s|ORION_PORT|${ORION_PORT}|g"

    # configure mosquitto
    sed -i /etc/init.d/mosquitto \
        -e "s|etc/mosquitto/mosquitto.conf|etc/iot/mosquitto.conf|g"

    sed -i /etc/iot/mosquitto.conf \
        -e "s|user root|user iotagent|g"

    exec /sbin/init
else
    exec "$@"
fi
