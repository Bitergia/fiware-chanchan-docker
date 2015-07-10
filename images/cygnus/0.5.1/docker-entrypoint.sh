#!/bin/bash
set -e

[ -z "${MYSQL_HOST}" ] && echo "Missing MYSQL_HOST variable." && exit 1
[ -z "${MYSQL_PORT}" ] && echo "Missing MYSQL_PORT variable." && exit 1
[ -z "${MYSQL_USER}" ] && echo "Missing MYSQL_USER variable." && exit 1
[ -z "${MYSQL_PASSWORD}" ] && echo "Missing MYSQL_PASSWORD variable." && exit 1

[ -z "${ORION_HOSTNAME}" ] && echo "ORION_HOSTNAME is undefined.  Using default value of 'orion'" && export ORION_HOSTNAME=orion
[ -z "${ORION_PORT}" ] && echo "ORION_PORT is undefined.  Using default value of '10026'" && export ORION_PORT=10026
[ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '30'" && export DEFAULT_MAX_TRIES=30

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

    if [ ! -e ${CURL} ] ; then
	echo "Unable to find 'curl' command."
	exit 1
    fi

    while [ ${_tries} -lt ${_max_tries} -a ${_ok} -eq 0 ] ; do
	echo -n "Checking url '${_url}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
	if ${CURL} -s ${_url} | grep -q "${_regex}" ; then
	    echo "OK."
	    _ok=1
	else
	    echo "Failed."
	    sleep 1
	    _tries=$(( ${_tries} + 1 ))
	fi
    done

    if [ ${_ok} -eq 0 ] ; then
	echo "Url check failed after ${_tries} tries."
	exit 1
    else
	echo "Url check succeeded."
    fi
}

if [ -f ${APACHE_FLUME_HOME}/conf/cygnus.conf ] ; then

    sed -i ${APACHE_FLUME_HOME}/conf/cygnus.conf \
	-e "s/api_key = API_KEY/api_key = ${CKAN_API_KEY}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_host=.*/cygnusagent.sinks.mysql-sink-thing.mysql_host=${MYSQL_HOST}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_port=.*/cygnusagent.sinks.mysql-sink-thing.mysql_port=${MYSQL_PORT}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_username=.*/cygnusagent.sinks.mysql-sink-thing.mysql_username=${MYSQL_USER}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_password=.*/cygnusagent.sinks.mysql-sink-thing.mysql_password=${MYSQL_PASSWORD}/g"

fi

if [ -e /subscribe-to-orion ] ; then
    CYGNUS_HOSTNAME=`hostname -i` # can't link orion to cygnus (circular link in docker). Use IP

    check_host_port ${ORION_HOSTNAME} ${ORION_PORT}

    echo "Testing if orion is ready at http://${ORION_HOSTNAME}:${ORION_PORT}/version"

    check_url http://${ORION_HOSTNAME}:${ORION_PORT}/version "<version>.*</version>"

    echo "subscribing to orion"
    # For all the organizations, subscribe to all changes to entities with names manual:*
    # To change to params: type:org_name
    cat <<EOF | curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @-
{
    "entities": [
	{
	    "type": "org_a",
	    "isPattern": "true",
	    "id": "manual:*"
	}
    ],
    "attributes": [
	"temperature"
    ],
    "reference": "http://${CYGNUS_HOSTNAME}:5001/notify",
    "duration": "P1M",
    "notifyConditions": [
	{
	    "type": "ONCHANGE",
	    "condValues": [
		"pressure"
	    ]
	}
    ],
    "throttling": "PT1S"
}
EOF

    echo "subscribing to orion"
    cat <<EOF | curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @-
{
    "entities": [
	{
	    "type": "org_b",
	    "isPattern": "true",
	    "id": "manual:*"
	}
    ],
    "attributes": [
	"temperature"
    ],
    "reference": "http://${CYGNUS_HOSTNAME}:5002/notify",
    "duration": "P1M",
    "notifyConditions": [
	{
	    "type": "ONCHANGE",
	    "condValues": [
		"pressure"
	    ]
	}
    ],
    "throttling": "PT1S"
}
EOF

    echo "subscribing to orion"
    # Santander sensors
    cat <<EOF | curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @-
{
    "entities": [
	{
	    "type": "santander:soundacc",
	    "isPattern": "true",
	    "id": "urn:smartsantander:testbed:*"
	}
    ],
    "reference": "http://${CYGNUS_HOSTNAME}:5050/notify",
    "duration": "P1M",
    "notifyConditions": [
	{
	    "type": "ONCHANGE",
	    "condValues": [
		"TimeInstant"
	    ]
	}
    ]
}
EOF

    echo "subscribing to orion"
    # IDAS temperature sensors
    cat <<EOF | curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @-
{
    "entities": [
	{
	    "type": "thing",
	    "isPattern": "true",
	    "id": "SENSOR_TEMP:*"
	}
    ],
    "attributes": [
	"temperature"
    ],
    "reference": "http://${CYGNUS_HOSTNAME}:6001/notify",
    "duration": "P1M",
    "notifyConditions": [
	{
	    "type": "ONCHANGE",
	    "condValues": [
		"TimeInstant"
	    ]
	}
    ],
    "throttling": "PT1S"
}
EOF

fi

exec /sbin/init
