#!/bin/bash

# Sleep 10 seconds to let the Authzforce interface set-up/

sleep 10

# Request to Authzforce to retrieve Domain

DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)" 

# Checks if the Domain exists. If not, creates one

if [ -z "$DOMAIN" ]; then 
    echo "Domain is not created yet!"
    curl -s --request POST --header "Content-Type: application/xml;charset=UTF-8" --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' --header "Accept: application/xml" http://authzforce:8080/authzforce/domains
    DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)"
    echo $DOMAIN
else
    echo "Domain value is not empty: "
    echo $DOMAIN
fi

# Configure PEP Proxy adding authzforce complete URL

sed -e "s@^    path:@    path:'/authzforce/domains/$DOMAIN/pdp'@" -i /opt/fi-ware-pep-proxy/config.js

# TEMP Perform the actions needed in IdM for the PEP authentication
# TODO Implement this actions while deploying IdM

sleep 10

FRESHTOKEN="$(curl -s -i   -H "Content-Type: application/json"   -d '{ "auth": {"identity": {"methods": ["password"], "password": { "user": { "name": "pepproxy@test.com", "domain": { "id": "default" }, "password": "test"} } } } }' http://idm:5000/v3/auth/tokens | grep ^X-Subject-Token: | awk '{print $2}')"
MEMBERID="$(curl -s -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://idm:5000/v3/roles | python -m json.tool | grep -iw id | awk -F'"' '{print $4}' | head -n 1)"
REQUEST="$(curl -s -X PUT -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://idm:5000/v3/domains/default/users/pepproxy/roles/${MEMBERID})"

# Start container back

exec /sbin/init
