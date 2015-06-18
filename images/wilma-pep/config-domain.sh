#!/bin/bash

# Sleep 10 seconds to let the Authzforce interface set-up/

sleep 10

# Request to Authzforce to retrieve Domain

DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)" 

# Checks if the Domain exists. If not, creates one

if [ -z "$DOMAIN" ]; then 
    echo "Domain is not created yet!"
    curl --request POST --header "Content-Type: application/xml;charset=UTF-8" --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' --header "Accept: application/xml" http://authzforce:8080/authzforce/domains
    DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)"
    echo $DOMAIN
else
    echo "Domain value is not empty: "
    echo $DOMAIN
fi

# Configure PEP Proxy adding authzforce complete URL

sed -e "s@^    path:@    path:'/authzforce/domains/$DOMAIN/pdp'@" -i /home/bitergia/fiware-pep-proxy/config.js

# Start container back

exec /sbin/init
