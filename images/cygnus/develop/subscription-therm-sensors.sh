#!/bin/bash

CYGNUS_HOST=$( hostname -i )
CYGNUS_PORT=5050
CYGNUS_URL=http://${CYGNUS_HOST}:${CYGNUS_PORT}/notify
ORION_URL=http://${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext

# IDAS temperature sensors
cat <<EOF | curl ${ORION_URL} -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @-
{
    "entities": [
        {
            "type": "thing",
            "isPattern": "true",
            "id": "SENSOR_TEMP_*"
        }
    ],
    "attributes": [
        "temperature"
    ],
    "reference": "${CYGNUS_URL}",
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
