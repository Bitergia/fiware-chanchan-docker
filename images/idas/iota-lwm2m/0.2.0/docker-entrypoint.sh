#!/bin/bash
set -e

source /entrypoint-common.sh

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    check_var MONGODB_HOSTNAME mongodb
    check_var MONGODB_PORT 27017
    check_var MONGODB_DATABASE iota-lwm2m
    check_var ORION_HOSTNAME orion
    check_var ORION_PORT 1026
    check_var IOTA_SERVER_PORT 4041
    check_var IOTA_DEFAULT_SERVICE bitergiaidas
    check_var IOTA_DEFAULT_SUBSERVICE /devices
    check_var IOTA_PATH /opt/iotagent-lwm2m

    if [ -z "${IOTA_SERVER_IP}" ]; then
        echo "IOTA_SERVER_IP is undefined.  Using container IP".
        # get container IP for providerUrl
        IOTA_SERVER_IP=$( grep ${HOSTNAME} /etc/hosts | awk '{print $1}' )
        [ -z "${IOTA_SERVER_IP}" ] && echo "Failed to get container IP for providerUrl." && exit 1
    fi

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
    sed -i ${IOTA_PATH}/config.js \
        -e "s|'MONGODB_HOSTNAME'|'${MONGODB_HOSTNAME}'|g" \
        -e "s|'MONGODB_PORT'|'${MONGODB_PORT}'|g" \
        -e "s|'MONGODB_DATABASE'|'${MONGODB_DATABASE}'|g" \
        -e "s|'ORION_HOSTNAME'|'${ORION_HOSTNAME}'|g" \
        -e "s|'ORION_PORT'|'${ORION_PORT}'|g" \
        -e "s|port: IOTA_SERVER_PORT|port: ${IOTA_SERVER_PORT}|g" \
        -e "s|'IOTA_DEFAULT_SERVICE'|'${IOTA_DEFAULT_SERVICE}'|g" \
        -e "s|'IOTA_DEFAULT_SUBSERVICE'|'${IOTA_DEFAULT_SUBSERVICE}'|g" \
        -e "s|providerUrl:.*|providerUrl: 'http://${IOTA_SERVER_IP}:${IOTA_SERVER_PORT}',|g"

    cd ${IOTA_PATH}
    su - ${IOTA_USER} -c "cd ${IOTA_PATH} ; forever start bin/lwm2mAgent.js"
    exec su - ${IOTA_USER} -c "forever --fifo logs 0"
else
    exec "$@"
fi
