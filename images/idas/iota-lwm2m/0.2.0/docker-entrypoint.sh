#!/bin/bash
set -e

function check_host_port () {

    local _timeout=10
    local _tries=0
    local _is_open=0

    if [ $# -lt 2 ] ; then
        echo "check_host_port: missing parameters."
        echo "Usage: check_host_port <host> <port> [max-tries]"
        exit 1
    fi

    local _host=$1
    local _port=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local NC=$( which nc )

    if [ ! -e "${NC}" ] ; then
        echo "Unable to find 'nc' command."
        exit 1
    fi

    echo "Testing if port '${_port}' is open at host '${_host}'."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_open} -eq 0 ] ; do
        echo -n "Checking connection to '${_host}:${_port}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${NC} -z -w ${_timeout} ${_host} ${_port} ; then
            echo "OK."
            _is_open=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_is_open} -eq 0 ] ; then
        echo "Failed to connect to port '${_port}' on host '${_host}' after ${_tries} tries."
        echo "Port is closed or host is unreachable."
        exit 1
    else
        echo "Port '${_port}' at host '${_host}' is open."
    fi
}

function check_url () {

    local _timeout=10
    local _tries=0
    local _ok=0

    if [ $# -lt 2 ] ; then
        echo "check_url: missing parameters."
        echo "Usage: check_url <url> <regex> [max-tries]"
        exit 1
    fi

    local _url=$1
    local _regex=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local CURL=$( which curl )

    if [[ -z "${CURL}" || ! -e ${CURL} ]] ; then
        echo "Unable to find 'curl' command."
        exit 1
    fi

    while [ ${_tries} -lt ${_max_tries} -a ${_ok} -eq 0 ] ; do
        echo -n "Checking url '${_url}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${CURL} -s ${_url} | grep -q "${_regex}" ; then
            echo "OK."
            _ok=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_ok} -eq 0 ] ; then
        echo "Url check failed after ${_tries} tries."
        exit 1
    else
        echo "Url check succeeded."
    fi
}

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    [ -z "${MONGODB_HOSTNAME}" ] && echo "MONGODB_HOSTNAME is undefined.  Using default value of 'mongodb'" && export MONGODB_HOSTNAME=mongodb
    [ -z "${MONGODB_PORT}" ] && echo "MONGODB_PORT is undefined.  Using default value of '27017'" && export MONGODB_PORT=27017
    [ -z "${MONGODB_DATABASE}" ] && echo "MONGODB_DATABASE is undefined.  Using default value of 'iot-lwm2m'" && export MONGODB_DATABASE=iot-lwm2m
    [ -z "${ORION_HOSTNAME}" ] && echo "ORION_HOSTNAME is undefined.  Using default value of 'orion'" && export ORION_HOSTNAME=orion
    [ -z "${ORION_PORT}" ] && echo "ORION_PORT is undefined.  Using default value of '10026'" && export ORION_PORT=10026
    [ -z "${IOTA_SERVER_PORT}" ] && echo "IOTA_SERVER_PORT is undefined.  Using default value of '4041'" && export IOTA_SERVER_PORT=4041
    [ -z "${IOTA_DEFAULT_SERVICE}" ] && echo "IOTA_DEFAULT_SERVICE is undefined.  Using default value of 'bitergiaidas'" && export IOTA_DEFAULT_SERVICE=bitergiaidas
    [ -z "${IOTA_DEFAULT_SUBSERVICE}" ] && echo "IOTA_DEFAULT_SUBSERVICE is undefined.  Using default value of '/devices'" && export IOTA_DEFAULT_SUBSERVICE=/devices
    [ -z "${IOTA_PATH}" ] && echo "IOTA_PATH is undefined.  Using default value of '/opt/iotagent-lwm2m'" && export IOTA_PATH=/opt/iotagent-lwm2m
    [ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '60'" && export DEFAULT_MAX_TRIES=60

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
