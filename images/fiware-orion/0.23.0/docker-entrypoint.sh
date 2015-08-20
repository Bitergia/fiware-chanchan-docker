#!/bin/bash
set -e

param_dbhost=0
param_port=0
param_pidpath=0

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
	return 1
    else
	echo "Port '${_port}' at host '${_host}' is open."
    fi
}

function check_mongodb () {
    local dbhost="$1"
    local ret=1

    # split hosts
    IFS="," read -ra MONGO_HOSTS <<< "${dbhost}"
    for mongo_host in "${MONGO_HOSTS[@]}"; do
	IFS=":" read host port <<< "${mongo_host}"
	if [ -z "${port}" ]; then
	    echo "No port specified for host '${host}'.  Using mongo default of '27017'."
	    port="27017"
	fi
	if check_host_port ${host} ${port} ; then
	    ret=0
	fi
    done
    return $ret
}

if [ "${1:0:1}" = '-' ]; then
	set -- /usr/bin/contextBroker "$@"
fi

if [ "${1}" = "/usr/bin/contextBroker" ] ; then

    if [ -z "${DEFAULT_MAX_TRIES}" ]; then
	echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '60'"
	export DEFAULT_MAX_TRIES=60
    fi

    # check specified parameters

    if [[ "$*" =~ \ -port\ ([^\ ]+) ]]; then
	param_port=1
	export ORION_PORT=${BASH_REMATCH[1]}
    elif [[ "$*" =~ \ -dbhost\ ([^\ ]+) ]]; then
	param_dbhost=1
	if [[ -n "${MONGODB_HOSTNAME}" || -n "${MONGODB_PORT}" ]] ; then
	    echo "WARNING: -dbhost parameter overrides MONGODB_HOSTNAME and MONGODB_PORT environments variables."
	fi
	if ! check_mongodb "${BASH_REMATCH[1]}" ; then
	    echo "All checks failed for dbhost value: ${BASH_REMATCH[1]}."
	    exit 1
	fi

    elif [[ "$*" =~ \ -pidpath\  ]]; then
	param_pidpath=1
    fi

    # add defaults for non-specified parameters

    if [ ${param_port} -eq 0 ]; then
	echo "No '-port' parameter specified.  Using value from ORION_PORT environment variable."
	if [ -z "${ORION_PORT}" ]; then
	    echo "ORION_PORT is undefined.  Using default value of '1026'"
	    export ORION_PORT=1026
	fi
	# fix variables when using docker-compose
	if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	    export ORION_PORT=${BASH_REMATCH[1]}
	fi
	set -- "$@" -port ${ORION_PORT}
    fi

    if [ ${param_dbhost} -eq 0 ]; then
	echo "No 'dbhost' parameter specified.  Using values from MONGODB_HOSTNAME and MONGODB_PORT environment variables."
	if [ -z "${MONGODB_HOSTNAME}" ]; then
	    echo "MONGODB_HOSTNAME is undefined.  Using default value of 'mongodb'"
	    export MONGODB_HOSTNAME=mongodb
	fi
	if [ -z "${MONGODB_PORT}" ]; then
	    echo "MONGODB_PORT is undefined.  Using default value of '27017'"
	    export MONGODB_PORT=27017
	fi
	# fix variables when using docker-compose
	if [[ ${MONGODB_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	    export MONGODB_PORT=${BASH_REMATCH[1]}
	fi

	check_host_port ${MONGODB_HOSTNAME} ${MONGODB_PORT}
	set -- "$@" -dbhost ${MONGODB_HOSTNAME}:${MONGODB_PORT}
    fi

    if [ ${param_pidpath} -eq 0 ]; then
	set -- "$@" -pidpath /var/run/contextBroker/contextBroker.pid
    fi

fi

exec "$@"
