#!/bin/bash

AUTHZFORCE_HOSTNAME=authzforce
AUTHZFORCE_PORT=8080
TIMEOUT=10
try=0
ok=0

echo "Testing Authzforce port"
while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
        echo "Checking connection with Authzforce at ${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT} (try $try)..."
        if nc -z -w $TIMEOUT $AUTHZFORCE_HOSTNAME $AUTHZFORCE_PORT ; then
            # Authzforce is up
            ok=1
        else
            # keep waiting
            sleep 1
            try=$(( $try + 1 ))
        fi
done
if [ ! $ok ] ; then
        echo "Failed to connect to Authzforce at ${AUHTZFORCE_HOSTNAME}:${AUTHFORCE_PORT}"
        exit 1
fi

# Request to Authzforce to retrieve Domain

try=0
ok=0
echo "Testing Authzforce url"
while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
        echo "Checking if Authzforce is ready at ${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains (try $try)..."
        if curl ${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains -s | grep -q href ; then
            ok=1
            echo "Authzforce is ready!"
        else
            sleep 1
            try=$(( $try + 1 ))
        fi
done
if [ ! $ok ] ; then
        echo "Failed to connect to Authzforce at ${AUHTZFORCE_HOSTNAME}:${AUTHFORCE_PORT}"
        exit 1
fi

# Request to Authzforce to retrieve Domain

DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)" 

# Checks if the Domain exists. If not, creates one

if [ -z "$DOMAIN" ]; then 
    echo "Domain is not created yet!"
    curl -s --request POST --header "Content-Type: application/xml;charset=UTF-8" --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' --header "Accept: application/xml" http://authzforce:8080/authzforce/domains --output /dev/null
    DOMAIN="$(curl -s --request GET http://authzforce:8080/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)"
    echo "Domain has been created: $DOMAIN"
else
    echo "Domain value is not empty: "
    echo $DOMAIN
fi

# Configure PEP Proxy adding authzforce complete URL

sed -e "s@^    path:@    path:'/authzforce/domains/$DOMAIN/pdp'@" -i /opt/fi-ware-pep-proxy/config.js

# Check that IdM is up and responsive 

IDM_HOSTNAME=idm
IDM_PORT=5000
try=0
ok=0

echo "Testing Keystone port"
while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
        echo "Checking connection with Keystone at ${IDM_HOSTNAME}:${IDM_PORT} (try $try)..."
        if nc -z -w $TIMEOUT $IDM_HOSTNAME $IDM_PORT ; then
            # Keystone is up
            ok=1
            echo "Keystone is ready!"
        else
            # keep waiting
            sleep 1
            try=$(( $try  1 ))
        fi
done
if [ ! $ok ] ; then
        echo "Failed to connect to Keystone at ${IDM_HOSTNAME}:${IDM_PORT}"
        exit 1
fi

# Configure Domain permissions to user 'pepproxy' at IdM

FRESHTOKEN="$(curl -s -i   -H "Content-Type: application/json"   -d '{ "auth": {"identity": {"methods": ["password"], "password": { "user": { "name": "idm", "domain": { "id": "default" }, "password": "idm"} } } } }' http://${IDM_HOSTNAME}:${IDM_PORT}/v3/auth/tokens | grep ^X-Subject-Token: | awk '{print $2}')"
MEMBERID="$(curl -s -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://${IDM_HOSTNAME}:${IDM_PORT}/v3/roles | python -m json.tool | grep -iw id | awk -F'"' '{print $4}' | head -n 1)"
REQUEST="$(curl -s -X PUT -H "X-Auth-Token:$FRESHTOKEN" -H "Content-type: application/json" http://${IDM_HOSTNAME}:${IDM_PORT}/v3/domains/default/users/pepproxy/roles/${MEMBERID})"

echo "User pepproxy has been granted with:"
echo "Role: ${MEMBERID}"
echo "Token:  $FRESHTOKEN"

# Start container back

exec /sbin/init
