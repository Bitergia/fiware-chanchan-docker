#!/bin/bash

# Sleep 5 seconds to let the Authzforce interface set-up

sleep 5

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

# TODO: retrieve magic_key automatically

sed -e "s@^ACCESS_CONTROL_URL = None@ACCESS_CONTROL_URL = 'http://authzforce:8080/authzforce/domains/${DOMAIN}/pap/policySet'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py
sed -e "s@^ACCESS_CONTROL_MAGIC_KEY = None@ACCESS_CONTROL_MAGIC_KEY = 'daf26216c5434a0a80f392ed9165b3b4'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py

# Start container back

exec /sbin/init
