#!/bin/bash

declare DOMAIN=''

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
        echo "Failed."
        sleep 1
        _tries=$(( ${_tries} + 1 ))
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

function get_domain () {

    if [ $# -lt 2 ] ; then
    echo "check_host_port: missing parameters."
    echo "Usage: check_host_port <host> <port> [max-tries]"
    exit 1
    fi

    local _host=$1
    local _port=$2

    # Request to Authzforce to retrieve Domain

    DOMAIN="$(curl -s --request GET http://${_host}:${_port}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)" 
    echo "Domain retrieved: $DOMAIN"

}

# Configure Domain permissions to user 'pepproxy' at IdM. 
# TODO: make it more configurable

function domain_permissions() {

    local _host=$1
    local _port=$2

    FRESHTOKEN="$(curl -s -i   -H "Content-Type: application/json"   -d '{ "auth": {"identity": {"methods": ["password"], "password": { "user": { "name": "idm", "domain": { "id": "default" }, "password": "idm"} } } } }' http://${_host}:${_port}/v3/auth/tokens | grep ^X-Subject-Token: | awk '{print $2}')"
    MEMBERID="$(curl -s -H "X-Auth-Token:${FRESHTOKEN}" -H "Content-type: application/json" http://${_host}:${_port}/v3/roles | python -m json.tool | grep -iw id | awk -F'"' '{print $4}' | head -n 1)"
    REQUEST="$(curl -s -X PUT -H "X-Auth-Token:${FRESHTOKEN}" -H "Content-type: application/json" http://${_host}:${_port}/v3/domains/default/users/pepproxy/roles/${MEMBERID})"
    echo "User pepproxy has been granted with:"
    echo "Role: ${MEMBERID}"
    echo "Token:  ${FRESHTOKEN}"

}

function check_file () {

    local _tries=0
    local _is_available=0

    local _file=$1
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}

    echo "Testing if file '${_file}' is available."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_available} -eq 0 ] ; do
        echo -n "Checking file '${_file}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if [ -r ${_file} ] ; then
            echo "OK."
            _is_available=1
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

    if [ ${_is_available} -eq 0 ] ; then
    echo "Failed to to retrieve '${_file}' after ${_tries} tries."
    echo "File is unavailable."
    exit 1
    else
    echo "File '${_file}' is available."
    fi
}

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    [ -z "${AUTHZFORCE_HOSTNAME}" ] && echo "AUTHZFORCE_HOSTNAME is undefined.  Using default value of 'authzforce'" && export AUTHZFORCE_HOSTNAME=authzforce
    [ -z "${AUTHZFORCE_PORT}" ] && echo "AUTHZFORCE_PORT is undefined.  Using default value of '8080'" && export AUTHZFORCE_PORT=8080
    [ -z "${IDM_KEYSTONE_HOSTNAME}" ] && echo "IDM_HOSTNAME is undefined.  Using default value of 'idm'" && export IDM_KEYSTONE_HOSTNAME=idm
    [ -z "${IDM_KEYSTONE_PORT}" ] && echo "IDM_PORT is undefined.  Using default value of '5000'" && export IDM_KEYSTONE_PORT=5000
    [ -z "${APP_HOSTNAME}" ] && echo "APP_HOSTNAME is undefined.  Using default value of 'orion'" && export APP_HOSTNAME=orion
    [ -z "${APP_PORT}" ] && echo "APP_PORT is undefined.  Using default value of '10026'" && export APP_PORT=10026
    [ -z "${PEP_USERNAME}" ] && echo "PEP_USERNAME is undefined. Using default value of 'pepproxy@test.com'" && export PEP_USERNAME=pepproxy@test.com
    [ -z "${PEP_PASSWORD}" ] && echo "PEP_PASSWORD is undefined. Using default value of 'test'" && export PEP_PASSWORD=test
    [ -z "${PEP_PORT}" ] && echo "PEP_PORT is undefined. Using default value of '1026'" && export PEP_PORT=1026
    [ -z "${IDM_USERNAME}" ] && echo "IDM_USERNAME is undefined. Using default value of 'user0@test.com'" && export IDM_USERNAME=user0@test.com
    [ -z "${IDM_USERPASS}" ] && echo "IDM_USERPASS is undefined. Using default value of 'test'" && export IDM_USERPASS=test
    [ -z "${MAGIC_KEY}" ] && echo "MAGIC_KEY is undefined. Using default value of 'daf26216c5434a0a80f392ed9165b3b4'" && export MAGIC_KEY=daf26216c5434a0a80f392ed9165b3b4
    [ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '60'" && export DEFAULT_MAX_TRIES=60

    # fix variables when using docker-compose
    if [[ ${AUTHZFORCE_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export AUTHZFORCE_PORT=${BASH_REMATCH[1]}
    fi
    if [[ ${IDM_KEYSTONE_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export IDM_KEYSTONE_PORT=${BASH_REMATCH[1]}
    fi
    if [[ ${APP_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export ORION_PORT=${BASH_REMATCH[1]}
    fi

    # Call checks

    check_file /config/domain-ready
    get_domain ${AUTHZFORCE_HOSTNAME} ${AUTHZFORCE_PORT}
    check_file /config/provision-ready
    check_host_port ${IDM_KEYSTONE_HOSTNAME} ${IDM_KEYSTONE_PORT}
    domain_permissions ${IDM_KEYSTONE_HOSTNAME} ${IDM_KEYSTONE_PORT}

    # Configure PEP Proxy config.js

    sed -i /opt/fi-ware-pep-proxy/config.js \
	-e "s|PEP_PORT|${PEP_PORT}|g" \
	-e "s|IDM_KEYSTONE_HOSTNAME|${IDM_KEYSTONE_HOSTNAME}|g" \
	-e "s|IDM_KEYSTONE_PORT|${IDM_KEYSTONE_PORT}|g" \
	-e "s|APP_HOSTNAME|${APP_HOSTNAME}|g" \
	-e "s|APP_PORT|${APP_PORT}|g" \
	-e "s|PEP_USERNAME|${PEP_USERNAME}|g" \
	-e "s|PEP_PASSWORD|${PEP_PASSWORD}|g" \
	-e "s|AUTHZFORCE_HOSTNAME|${AUTHZFORCE_HOSTNAME}|g" \
	-e "s|AUTHZFORCE_PORT|${AUTHZFORCE_PORT}|g" \
	-e "s|DOMAIN|${DOMAIN}|g" \
	-e "s|MAGIC_KEY|${MAGIC_KEY}|g"

    # Start PEP Proxy

    cd ${WILMA_HOME}
    su - ${WILMA_USER} -c "cd ${WILMA_HOME} ; PORT=${PEP_PORT} NODE_ENV=development forever start server.js"
    exec su - ${WILMA_USER} -c "forever --fifo logs 0"
else
    exec "$@"
fi
