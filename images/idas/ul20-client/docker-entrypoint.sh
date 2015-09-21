#!/bin/bash
set -e

source /entrypoint-common.sh

FIGWAY_SCRIPTS_PATH=/opt/fiware-figway/python-IDAS4
FIGWAY_CONFIG_FILE=${FIGWAY_SCRIPTS_PATH}/config.ini
IDAS_SCRIPTS_PATH=${FIGWAY_SCRIPTS_PATH}/Sensors_UL20

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

    check_var ORION_HOSTNAME orion
    check_var ORION_PORT 1026

    if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export ORION_PORT=${BASH_REMATCH[1]}
    fi

    check_var IOTA_HOSTNAME iota
    check_var IOTA_PORT 8080

    if [[ ${IOTA_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
	export IOTA_PORT=${BASH_REMATCH[1]}
    fi

    [ -z "${UL20_USERNAME}" ] && echo "UL20_USERNAME is undefined.  Using default value of ''" && export UL20_USERNAME=
    check_var UL20_USER_TOKEN NULL
    check_var UL20_CB_HOST ${ORION_HOSTNAME}
    check_var UL20_CB_PORT ${ORION_PORT}
    check_var UL20_CB_OAUTH no
    check_var UL20_SERVICE_NAME "devguideiot"
    check_var UL20_SERVICE_PATH "/"
    check_var UL20_IOTA_HOST ${IOTA_HOSTNAME}
    check_var UL20_IOTA_PORT ${IOTA_PORT}
    check_var UL20_IOTA_ADMIN_PORT ${IOTA_PORT}
    check_var UL20_IOTA_OAUTH no
    check_var UL20_API_KEY "devguideiot"
    check_var UL20_HOST_TYPE "Docker"
    check_var UL20_HOST_ID ${HOSTNAME}

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
