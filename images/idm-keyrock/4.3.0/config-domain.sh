#!/bin/bash

AUTHZFORCE_HOSTNAME=authzforce
AUTHZFORCE_PORT=8080
TIMEOUT=10
try=0
ok=0

# Request to Authzforce to retrieve Domain

try=0
ok=0
echo "Testing Authzforce url"
while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
	echo "Checking if Authzforce is ready at ${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains (try $try)..."
	if curl ${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains -s | grep -q href ; then
	    ok=1
            DOMAIN="$(curl -s --request GET http://${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2)"
	else
	    sleep 1
	    try=$(( $try + 1 ))
	fi
done
if [ ! $ok ] ; then
        echo "Failed to connect to Authzforce at ${AUHTZFORCE_HOSTNAME}:${AUTHFORCE_PORT}"
        exit 1
fi

# Parse the value into the IdM settings

sed -e "s@^ACCESS_CONTROL_URL = None@ACCESS_CONTROL_URL = 'http://authzforce:8080/authzforce/domains/${DOMAIN}/pap/policySet'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py
sed -e "s@^ACCESS_CONTROL_MAGIC_KEY = None@ACCESS_CONTROL_MAGIC_KEY = 'daf26216c5434a0a80f392ed9165b3b4'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py

# Start container back

exec /sbin/init
