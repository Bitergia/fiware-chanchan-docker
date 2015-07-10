#!/bin/bash
set -e

[ -z "${MONGODB_HOSTNAME}" ] && echo "MONGODB_HOSTNAME is undefined.  Using default value of 'mongodb'" && export MONGODB_HOSTNAME=mongodb
[ -z "${MONGODB_PORT}" ] && echo "MONGODB_PORT is undefined.  Using default value of '27017'" && export MONGODB_PORT=27017
[ -z "${ORION_PORT}" ] && echo "ORION_PORT is undefined.  Using default value of '10026'" && export ORION_PORT=10026

[ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '30'" && export DEFAULT_MAX_TRIES=30

# fix variables when using docker-compose
if [[ ${MONGODB_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export MONGODB_PORT=${BASH_REMATCH[1]}
fi

if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export ORION_PORT=${BASH_REMATCH[1]}
fi

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
	echo -n "Checking connection to '${_host}:${_port}' [try $(( ${_tries} + 1 ))] ... "
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

check_host_port ${MONGODB_HOSTNAME} ${MONGODB_PORT}

# configure orion
sed -i /etc/sysconfig/contextBroker \
    -e "s/^BROKER_DATABASE_HOST=.*/BROKER_DATABASE_HOST=${MONGODB_HOSTNAME}/g" \
    -e "s/^BROKER_PORT=.*/BROKER_PORT=${ORION_PORT}/g"

exec /sbin/init
