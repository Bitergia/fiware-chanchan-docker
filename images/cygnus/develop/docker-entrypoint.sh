#!/bin/bash
set -e

function check_host_port () {

    local _timeout=10
    local _tries=0
    local _is_open=0

    if [ $# -lt 2 ] ; then
        echo "check_host_port: missing parameters."
        echo "Usage: check_host_port <host> <port> [max-tries]"
        exit 1
    fi

    local _host=$1
    local _port=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local NC=$( which nc )

    if [ ! -e "${NC}" ] ; then
        echo "Unable to find 'nc' command."
        exit 1
    fi

    echo "Testing if port '${_port}' is open at host '${_host}'."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_open} -eq 0 ] ; do
        echo -n "Checking connection to '${_host}:${_port}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${NC} -z -w ${_timeout} ${_host} ${_port} ; then
            echo "OK."
            _is_open=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_is_open} -eq 0 ] ; then
        echo "Failed to connect to port '${_port}' on host '${_host}' after ${_tries} tries."
        echo "Port is closed or host is unreachable."
        exit 1
    else
        echo "Port '${_port}' at host '${_host}' is open."
    fi
}

function check_url () {

    local _timeout=10
    local _tries=0
    local _ok=0

    if [ $# -lt 2 ] ; then
        echo "check_url: missing parameters."
        echo "Usage: check_url <url> <regex> [max-tries]"
        exit 1
    fi

    local _url=$1
    local _regex=$2
    local _max_tries=${3:-${DEFAULT_MAX_TRIES}}
    local CURL=$( which curl )

    if [ ! -e ${CURL} ] ; then
        echo "Unable to find 'curl' command."
        exit 1
    fi

    while [ ${_tries} -lt ${_max_tries} -a ${_ok} -eq 0 ] ; do
        echo -n "Checking url '${_url}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if ${CURL} -s ${_url} | grep -q "${_regex}" ; then
            echo "OK."
            _ok=1
        else
            sleep 1
            _tries=$(( ${_tries} + 1 ))
            if [ ${_tries} -lt ${_max_tries} ] ; then
                echo "Retrying."
            else
                echo "Failed."
            fi
        fi
    done

    if [ ${_ok} -eq 0 ] ; then
        echo "Url check failed after ${_tries} tries."
        exit 1
    else
        echo "Url check succeeded."
    fi
}

function check_var () {
    local var_name="$1"
    local default_value="$2"

    if [ -z "$( eval echo \$${var_name} )" ] ; then
        if [ -z "${default_value}" ] ; then
            echo "Missing required variable '${var_name}'"
            exit 1
        else
            echo "${var_name} is undefined. Using default value of '${default_value}'"
            export $( eval echo ${var_name} )=${default_value}
        fi
    fi
}

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

        check_var DEFAULT_MAX_TRIES 60

        check_var ORION_HOSTNAME orion
        check_var ORION_PORT 1026

        if [[ ${ORION_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
            export ORION_PORT=${BASH_REMATCH[1]}
        fi

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
