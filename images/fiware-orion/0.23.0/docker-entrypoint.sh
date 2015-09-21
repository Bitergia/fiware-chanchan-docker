#!/bin/bash
set -e

source /entrypoint-common.sh

param_dbhost=0
param_port=0
param_pidpath=0

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
	check_var ORION_PORT 1026
	# fix variables when using docker-compose
	if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	    export ORION_PORT=${BASH_REMATCH[1]}
	fi
	set -- "$@" -port ${ORION_PORT}
    fi

    if [ ${param_dbhost} -eq 0 ]; then
	echo "No 'dbhost' parameter specified.  Using values from MONGODB_HOSTNAME and MONGODB_PORT environment variables."
	check_var MONGODB_HOSTNAME mongodb
	check_var MONGODB_PORT 27017
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
