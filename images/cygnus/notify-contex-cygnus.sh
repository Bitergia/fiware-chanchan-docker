#!/bin/bash

ORION_HOSTNAME=localhost
ORION_PORT=1026
CYGNUS_HOSTNAME=localhost

# For all the organizations, subscribe to all changes to entities with names manual:*
# To change to params: type:org_name
(curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @- | python -mjson.tool) <<EOF
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

(curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @- | python -mjson.tool) <<EOF
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

# Santander sensors
(curl ${ORION_HOSTNAME}:${ORION_PORT}/NGSI10/subscribeContext -s -S --header 'Content-Type: application/json' --header 'Accept: application/json' -d @- | python -mjson.tool) <<EOF
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
