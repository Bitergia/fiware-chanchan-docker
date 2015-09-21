#!/bin/bash
set -e

source /entrypoint-common.sh

check_var MYSQL_HOST
check_var MYSQL_PORT
check_var MYSQL_USER
check_var MYSQL_PASSWORD

check_var ORION_HOSTNAME orion
check_var ORION_PORT 1026

if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
    export ORION_PORT=${BASH_REMATCH[1]}
fi

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
