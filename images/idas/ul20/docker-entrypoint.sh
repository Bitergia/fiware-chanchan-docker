#!/bin/bash
set -e

MONGODB_HOSTNAME=mongodb
MONGODB_PORT=27017

# wait for mongo
TIMEOUT=10
try=0
ok=0
echo "Testing mongodb port"
while [ $try -lt $TIMEOUT -a $ok -eq 0 ] ; do
    echo "Checking connection with mongodb at ${MONGODB_HOSTNAME}:${MONGODB_PORT} (try $try)..."
    if nc -z -w $TIMEOUT $MONGODB_HOSTNAME $MONGODB_PORT ; then
	# mongodb is up
	ok=1
    else
	# keep waiting
	sleep 1
	try=$(( $try + 1 ))
    fi
done
if [ ! $ok ] ; then
    echo "Failed to connect to mongodb at ${MONGODB_HOSTNAME}:${MONGODB_PORT}"
    exit 1
fi

exec /sbin/init
