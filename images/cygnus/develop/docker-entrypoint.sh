#!/bin/bash
set -e

source /entrypoint-common.sh

if [ "$#" -ne 0 ]; then
    set -- "$@"
else

    check_var LOG_LEVEL INFO
    export CONF_PATH=${FLUME_HOME}/conf
    export AGENT_NAME=cygnusagent

    if [ -f /config/cygnus.conf ] ; then

        # use user supplied configuration
        echo "Using user supplied configuration file '/config/cygnus.conf'."
        cp /config/cygnus.conf ${CONF_PATH}/cygnus.conf
        export CONF_FILE=${CONF_PATH}/cygnus.conf

    else

        # build configuration from templates
        echo "Building configuration file from template."
        cp ${CYGNUS_HOME}/conf/agent.conf.template ${CONF_PATH}/cygnus.conf
        export CONF_FILE=${CONF_PATH}/cygnus.conf

	check_var ENABLE_MYSQL yes

	if [ "${ENABLE_MYSQL}" = "yes" ] ; then
	    
            check_var MYSQL_HOST
            check_var MYSQL_PORT
            check_var MYSQL_USER
            check_var MYSQL_PASSWORD

            check_host_port ${MYSQL_HOST} ${MYSQL_PORT}

            sed -i ${CONF_FILE} \
		-e "s/^cygnusagent.sinks.mysql-sink.mysql_host =.*/cygnusagent.sinks.mysql-sink.mysql_host = ${MYSQL_HOST}/g" \
		-e "s/^cygnusagent.sinks.mysql-sink.mysql_port =.*/cygnusagent.sinks.mysql-sink.mysql_port = ${MYSQL_PORT}/g" \
		-e "s/^cygnusagent.sinks.mysql-sink.mysql_username =.*/cygnusagent.sinks.mysql-sink.mysql_username = ${MYSQL_USER}/g" \
		-e "s/^cygnusagent.sinks.mysql-sink.mysql_password =.*/cygnusagent.sinks.mysql-sink.mysql_password = ${MYSQL_PASSWORD}/g" \
		-e "s/^cygnusagent.sinks.mysql-sink.attr_persistence = .*/cygnusagent.sinks.mysql-sink.attr_persistence = row/g"

	    ENABLED_CHANNELS="${ENABLED_CHANNELS} mysql-channel"
	fi

	check_var ENABLED_CHANNELS
	
	sed -i ${CONF_FILE} \
	    -e "s/^cygnusagent.sources.http-source.channels = .*/cygnusagent.sources.http-source.channels = ${ENABLED_CHANNELS}/g"
    fi

    if [ "${1:0:1}" = '-' ]; then
        set -- ${FLUME_HOME}/bin/cygnus-flume-ng agent "$@"
    else
        set -- ${FLUME_HOME}/bin/cygnus-flume-ng agent --conf ${CONF_PATH} -f ${CONF_FILE} -n ${AGENT_NAME} -Dflume.root.logger=${LOG_LEVEL},console
    fi

    if [ -e /subscribe-to-orion ] ; then

        check_var ORION_HOSTNAME orion
        check_var ORION_PORT 1026

        if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
            export ORION_PORT=${BASH_REMATCH[1]}
        fi

        check_host_port ${ORION_HOSTNAME} ${ORION_PORT}

        echo "Testing if orion is ready at http://${ORION_HOSTNAME}:${ORION_PORT}/version"
        check_url http://${ORION_HOSTNAME}:${ORION_PORT}/version "<version>.*</version>"

        echo "subscribing to orion"
        for f in $( ls ${SUBSCRIPTIONS_PATH} ) ; do
            "${SUBSCRIPTIONS_PATH}/${f}"
        done
        rm -f /subscribe-to-orion
    fi
fi

exec "$@"
