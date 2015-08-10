#!/bin/bash
set -e

FIGWAY_SCRIPTS_PATH=/opt/fiware-figway/python-IDAS4
FIGWAY_CONFIG_FILE=${FIGWAY_SCRIPTS_PATH}/config.ini
IDAS_SCRIPTS_PATH=${FIGWAY_SCRIPTS_PATH}/Sensors_UL20

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
	return 1
    else
	echo "Port '${_port}' at host '${_host}' is open."
    fi
}

function register_service () {

    local service_name="$1"
    local api_key="$2"
    local orion_host="$3"
    local orion_port="$4"
    local ret=1

    cd ${IDAS_SCRIPTS_PATH}
    local output=$( python CreateService.py ${service_name} ${api_key} ${orion_host} ${orion_port} )
    status_code=$( echo "${output}" | sed -n -e 's/^\* Status Code: \(.\+\)$/\1/g p' )

    case "${status_code}" in
	201)
	    echo "Registered new service '${service_name}'"
	    ret=0
	    ;;
	409)
	    if echo "${output}" | grep -q "object already exists" ; then
		echo "Service '${service_name}' is already registered."
		ret=0
	    else
		echo "${output}"
		ret=1
	    fi
	    ;;
	*)
	    echo "${output}"
	    ret=1
	    ;;
    esac
    return $ret
}

function register_sensors () {

    local id="$1"
    local type="$( echo $2 | sed -e 's/ /_/g')"
    local device_id="${HOSTNAME}_Thermal_${type}_${id}"
    local entity_id="SENSOR_TEMP_${type}_${id}_${HOSTNAME}"
    local ret=1

    cd ${IDAS_SCRIPTS_PATH}
    local output=$( python RegisterDevice.py SENSOR_TEMP ${device_id} ${entity_id} )

    status_code=$( echo "${output}" | sed -n -e 's/^\* Status Code: \(.\+\)$/\1/g p' )

    case "${status_code}" in
	201)
	    echo "Registered new device '${device_id}' on entity '${entity_id}'"
	    ret=0
	    ;;
	*)
	    echo "${output}"
	    ret=1
	    ;;
    esac

    return $ret
}

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    [ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '30'" && export DEFAULT_MAX_TRIES=30

    [ -z "${ORION_HOSTNAME}" ] && echo "ORION_HOSTNAME is undefined.  Using default value of 'orion'" && export ORION_HOSTNAME=orion
    [ -z "${ORION_PORT}" ] && echo "ORION_PORT is undefined.  Using default value of '1026'" && export ORION_PORT=1026

    if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export ORION_PORT=${BASH_REMATCH[1]}
    fi

    [ -z "${IOTA_HOSTNAME}" ] && echo "IOTA_HOSTNAME is undefined.  Using default value of 'iota'" && export IOTA_HOSTNAME=iota
    [ -z "${IOTA_PORT}" ] && echo "IOTA_PORT is undefined.  Using default value of '8080'" && export IOTA_PORT=8080

    if [[ ${IOTA_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export IOTA_PORT=${BASH_REMATCH[1]}
    fi

    [ -z "${UL20_USERNAME}" ] && echo "UL20_USERNAME is undefined.  Using default value of ''" && export UL20_USERNAME=
    [ -z "${UL20_USER_TOKEN}" ] && echo "UL20_USER_TOKEN is undefined.  Using default value of 'NULL'" && export UL20_USER_TOKEN=NULL
    [ -z "${UL20_CB_HOST}" ] && echo "UL20_CB_HOST is undefined.  Using default value of '${ORION_HOSTNAME}'" && export UL20_CB_HOST=${ORION_HOSTNAME}
    [ -z "${UL20_CB_PORT}" ] && echo "UL20_CB_PORT is undefined.  Using default value of '${ORION_PORT}'" && export UL20_CB_PORT=${ORION_PORT}
    [ -z "${UL20_CB_OAUTH}" ] && echo "UL20_CB_OAUTH is undefined.  Using default value of 'no'" && export UL20_CB_OAUTH=no
    [ -z "${UL20_SERVICE_NAME}" ] && echo "UL20_SERVICE_NAME is undefined.  Using default value of 'devguideiot'" && export UL20_SERVICE_NAME="devguideiot"
    [ -z "${UL20_SERVICE_PATH}" ] && echo "UL20_SERVICE_PATH is undefined.  Using default value of '/'" && export UL20_SERVICE_PATH="/"
    [ -z "${UL20_IOTA_HOST}" ] && echo "UL20_IOTA_HOST is undefined.  Using default value of '${IOTA_HOSTNAME}'" && export UL20_IOTA_HOST=${IOTA_HOSTNAME}
    [ -z "${UL20_IOTA_PORT}" ] && echo "UL20_IOTA_PORT is undefined.  Using default value of '${IOTA_PORT}'" && export UL20_IOTA_PORT=${IOTA_PORT}
    [ -z "${UL20_IOTA_ADMIN_PORT}" ] && echo "UL20_IOTA_ADMIN_PORT is undefined.  Using default value of '${IOTA_PORT}'" && export UL20_IOTA_ADMIN_PORT=${IOTA_PORT}
    [ -z "${UL20_IOTA_OAUTH}" ] && echo "UL20_IOTA_OAUTH is undefined.  Using default value of 'no'" && export UL20_IOTA_OAUTH=no
    [ -z "${UL20_API_KEY}" ] && echo "UL20_API_KEY is undefined.  Using default value of 'devguideiot'" && export UL20_API_KEY="devguideiot"
    [ -z "${UL20_HOST_TYPE}" ] && echo "UL20_HOST_TYPE is undefined.  Using default value of 'Docker'" && export UL20_HOST_TYPE="Docker"
    [ -z "${UL20_HOST_ID}" ] && echo "UL20_HOST_ID is undefined.  Using default value of '${HOSTNAME}'" && export UL20_HOST_ID=${HOSTNAME}

    check_host_port ${ORION_HOSTNAME} ${ORION_PORT}
    check_host_port ${IOTA_HOSTNAME} ${IOTA_PORT}

    cat <<EOF | sed -i ${FIGWAY_CONFIG_FILE} -f -
/\[user\]/,/\[contextbroker\]/ {
s|username=.*|username=${UL20_USERNAME}|g
s|token=.*|token=${UL20_USER_TOKEN}|g
}

/\[contextbroker\]/,/\[idas\]/ {
s|host=.*|host=${UL20_CB_HOST}|g
s|port=.*|port=${UL20_CB_PORT}|g
s|OAuth=.*|OAuth=${UL20_CB_OAUTH}|g
s|fiware_service=.*|fiware_service=${UL20_SERVICE_NAME}|g
s|fiware-service-path=.*|fiware-service-path=${UL20_SERVICE_PATH}|g
}

/\[idas\]/,/\[local\]/ {
s|host=.*|host=${UL20_IOTA_HOST}|g
s|adminport=.*|adminport=${UL20_IOTA_ADMIN_PORT}|g
s|ul20port=.*|ul20port=${UL20_IOTA_PORT}|g
s|OAuth=.*|OAuth=${UL20_IOTA_OAUTH}|g
s|fiware-service=.*|fiware-service=${UL20_SERVICE_NAME}|g
s|fiware-service-path=.*|fiware-service-path=${UL20_SERVICE_PATH}|g
s|apikey=.*|apikey=${UL20_API_KEY}|g
}

/\[local\]/,$ {
s|host_type=.*|host_type=${UL20_HOST_TYPE}|g
s|host_id=.*|host_id=${UL20_HOST_ID}|g
}
EOF

    register_service ${UL20_SERVICE_NAME} ${UL20_API_KEY} ${ORION_HOSTNAME} ${ORION_PORT}

    exec bash -c "/opt/scripts/therm-sensors.sh $* | /opt/scripts/send-data.sh"
else
    exec "$@"
fi
