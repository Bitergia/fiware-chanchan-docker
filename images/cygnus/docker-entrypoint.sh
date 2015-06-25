#!/bin/bash
set -e

[ -z "${MYSQL_HOST}" ] && echo "Missing MYSQL_HOST variable." && exit 1
[ -z "${MYSQL_PORT}" ] && echo "Missing MYSQL_PORT variable." && exit 1
[ -z "${MYSQL_USER}" ] && echo "Missing MYSQL_USER variable." && exit 1
[ -z "${MYSQL_PASSWORD}" ] && echo "Missing MYSQL_PASSWORD variable." && exit 1

if [ -f ${APACHE_FLUME_HOME}/conf/cygnus.conf ] ; then

    sed -i ${APACHE_FLUME_HOME}/conf/cygnus.conf \
	-e "s/api_key = API_KEY/api_key = ${CKAN_API_KEY}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_host=.*/cygnusagent.sinks.mysql-sink-thing.mysql_host=${MYSQL_HOST}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_port=.*/cygnusagent.sinks.mysql-sink-thing.mysql_port=${MYSQL_PORT}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_username=.*/cygnusagent.sinks.mysql-sink-thing.mysql_username=${MYSQL_USER}/g" \
	-e "s/^cygnusagent.sinks.mysql-sink-thing.mysql_password=.*/cygnusagent.sinks.mysql-sink-thing.mysql_password=${MYSQL_PASSWORD}/g"

fi

if [ -e /subscribe-to-orion ] ; then
    ORION_HOSTNAME=orion
    ORION_PORT=10026
    CYGNUS_HOSTNAME=`hostname -i` # can't link orion to cygnus (circular link in docker). Use IP

    # wait for orion
    TIMEOUT=10
    try=0
    ok=0
    echo "Testing orion port"
    while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
	echo "Checking connection with orion at ${ORION_HOSTNAME}:${ORION_PORT} (try $try)..."
	if nc -z -w $TIMEOUT $ORION_HOSTNAME $ORION_PORT ; then
	    # orion is up
	    ok=1
	else
	    # keep waiting
	    sleep 1
	    try=$(( $try + 1 ))
	fi
    done
    if [ ! $ok ] ; then
	echo "Failed to connect to orion at ${ORION_HOSTNAME}:${ORION_PORT}"
	exit 1
    fi

    try=0
    ok=0
    echo "Testing orion url"
    while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
	echo "Checking if orion is ready at ${ORION_HOSTNAME}:${ORION_PORT}/version (try $try)..."
	if curl ${ORION_HOSTNAME}:${ORION_PORT}/version -s | grep -q "<version>.*</version>" ; then
	    ok=1
	else
	    sleep 1
	    try=$(( $try + 1 ))
	fi
    done

    if [ ! $ok ] ; then
	echo "Failed to connect to orion at ${ORION_HOSTNAME}:${ORION_PORT}"
	exit 1
    fi

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
