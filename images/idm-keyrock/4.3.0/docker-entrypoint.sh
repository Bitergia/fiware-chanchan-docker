#!/bin/bash

declare DOMAIN=''

# Function to check the availaibility of a host and its port

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

# Funtion that checks if the domain has been already created at Authzforce

function check_domain () {

    if [ $# -lt 2 ] ; then
        echo "check_host_port: missing parameters."
        echo "Usage: check_host_port <host> <port> [max-tries]"
        exit 1
    fi

    local _host=$1
    local _port=$2

    if [ -e /initialize-domain-request ] ; then

        # Creates the domain

        curl -s \
             --request POST \
             --header "Content-Type: application/xml;charset=UTF-8" \
             --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' \
             --header "Accept: application/xml" \
             --output /dev/null \
             http://${_host}:${_port}/authzforce/domains

        DOMAIN=$( curl -s --request GET http://${_host}:${_port}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2 )
        echo "Domain has been created: $DOMAIN"
        rm /initialize-domain-request
        touch /config/domain-ready

    else

        # Retrieves the already created one

        DOMAIN=$( curl -s --request GET http://${_host}:${_port}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2 )
        echo "Domain retrieved: $DOMAIN"

    fi
}

# Function that checks if a file is available

function check_file () {

    local _tries=0
    local _is_available=0

    local _file=$1
    local _max_tries=10
    local ret=0

    echo "Testing if file '${_file}' is available."

    while [ ${_tries} -lt ${_max_tries} -a ${_is_available} -eq 0 ] ; do
        echo -n "Checking file '${_file}' [try $(( ${_tries} + 1 ))/${_max_tries}] ... "
        if [ -r ${_file} ] ; then
            echo "OK."
            _is_available=1
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

    if [ ${_is_available} -eq 0 ] ; then
        echo "Failed to to retrieve '${_file}' after ${_tries} tries."
        echo "File is unavailable."
        ret=1
    else
        echo "File '${_file}' is available."
    fi
    return $ret
}

# Function to call a script that generates a JSON with the app information

function _config_file () {

    echo "Parsing App information into a JSON file"
    source /opt/fi-ware-idm/keystone/.venv/bin/activate
    python /opt/fi-ware-idm/keystone/params-config.py --name ${APP_NAME} --file ${CONFIG_FILE} --database ${KEYSTONE_DB}
}

# Syncronize roles and permissions to Authzforce from the scratch

function _authzforce_sync () {

    echo "Syncing with Authzforce."
    sed -i '/from deployment import keystone/a from deployment import access_control_sync' /opt/fi-ware-idm/fabfile.py
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
    workon idm_tools
    fab access_control_sync.sync
    echo "Authzforce sucessfully parsed."

}

# Provide a set of users, roles, permissions, etc to handle KeyRock

function _data_provision () {
    if [ -e /initialize-provision ] ; then

        local FILE=default_provision

        if check_file ${PROVISION_FILE} ; then
            FILE=keystone_provision
            cp ${PROVISION_FILE} /opt/fi-ware-idm/deployment/keystone_provision.py
        else
            echo "Launching default provision file"
        fi
        sed -i "/from deployment import keystone/a from deployment import ${FILE}" /opt/fi-ware-idm/fabfile.py

        source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
        workon idm_tools
        echo "Creating Keystone database."
        fab keystone.database_create
        echo "Provisioning users, roles, and apps."
        fab keystone.populate
        fab ${FILE}.test_data
        echo "Provision done."
        _config_file
        _authzforce_sync
        rm /initialize-provision
        touch /config/provision-ready

    else
        echo "Provision has been done already"
    fi

}

function start_keystone () {
    echo "Starting Keystone server."
    (
        source /usr/share/virtualenvwrapper/virtualenvwrapper.sh
        workon idm_tools
        cd /opt/fi-ware-idm/keystone/
        ./tools/with_venv.sh bin/keystone-all ${KEYSTONE_VERBOSE_LOG} >> /var/log/keystone.log 2>&1 &
        # wait for keystone to be ready
        check_host_port localhost 5000
    )
}

function start_horizon () {
    echo "Starting Horizon server."
    service apache2 start
}

function tail_logs () {
    horizon_logs='/var/log/apache2/*.log'
    keystone_logs='/var/log/keystone.log'
    tail -F ${horizon_logs} ${keystone_logs}
}

if [ $# -eq 0 -o "${1:0:1}" = '-' ] ; then

    [ -z "${AUTHZFORCE_HOSTNAME}" ] && echo "AUTHZFORCE_HOSTNAME is undefined.  Using default value of 'authzforce'" && export AUTHZFORCE_HOSTNAME=authzforce
    [ -z "${AUTHZFORCE_PORT}" ] && echo "AUTHZFORCE_PORT is undefined.  Using default value of '8080'" && export AUTHZFORCE_PORT=8080
    [ -z "${IDM_KEYROCK_HOSTNAME}" ] && echo "IDM_KEYROCK_HOSTNAME is undefined.  Using default value of 'idm'" && export IDM_KEYROCK_HOSTNAME=idm
    [ -z "${IDM_KEYROCK_PORT}" ] && echo "IDM_KEYROCK_PORT is undefined.  Using default value of '443'" && export IDM_KEYROCK_PORT=443
    [ -z "${MAGIC_KEY}" ] && echo "MAGIC_KEY is undefined. Using default value of 'daf26216c5434a0a80f392ed9165b3b4'" && export MAGIC_KEY=daf26216c5434a0a80f392ed9165b3b4
    [ -z "${WORKON_HOME}" ] && echo "WORKON_HOME is undefined.  Using default value of '/opt/virtualenvs'" && export WORKON_HOME=/opt/virtualenvs
    [ -z "${APP_NAME}" ] && echo "APP_NAME is undefined.  Using default value of 'FIWAREdevGuide'" && export APP_NAME="FIWAREdevGuide"
    [ -z "${KEYSTONE_DB}" ] && echo "KEYSTONE_DB is undefined.  Using default value of '/opt/fi-ware-idm/keystone/keystone.db'" && export KEYSTONE_DB=/opt/fi-ware-idm/keystone/keystone.db
    [ -z "${CONFIG_FILE}" ] && echo "CONFIG_FILE is undefined.  Using default value of '/config/idm2chanchan.json'" && export CONFIG_FILE=/config/idm2chanchan.json
    [ -z "${PROVISION_FILE}" ] && echo "PROVISION_FILE is undefined.  Using default value of '/config/keystone_provision.py'" && export PROVISION_FILE=/config/keystone_provision.py
    [ -z "${DEFAULT_MAX_TRIES}" ] && echo "DEFAULT_MAX_TRIES is undefined.  Using default value of '30'" && export DEFAULT_MAX_TRIES=30
    [ -z "${KEYSTONE_VERBOSE}" ] && echo "KEYSTONE_VERBOSE is undefined.  Using default value of 'no'" && export KEYSTONE_VERBOSE=no

    # fix variables when using docker-compose
    if [[ ${AUTHZFORCE_PORT} =~ ^tcp://[^:]+:(.*)$ ]] ; then
        export AUTHZFORCE_PORT=${BASH_REMATCH[1]}
    fi

    if [ "${KEYSTONE_VERBOSE}" = "yes" ] ; then
        export KEYSTONE_VERBOSE_LOG="-v"
    else
        export KEYSTONE_VERBOSE_LOG=""
    fi

    # Call checks

    check_host_port ${AUTHZFORCE_HOSTNAME} ${AUTHZFORCE_PORT}
    check_domain ${AUTHZFORCE_HOSTNAME} ${AUTHZFORCE_PORT}

    start_keystone

    tail_logs & _waitpid=$!

    # Parse the value into the IdM settings

    sed -e "s@^ACCESS_CONTROL_URL = None@ACCESS_CONTROL_URL = 'http://${AUTHZFORCE_HOSTNAME}:${AUTHZFORCE_PORT}/authzforce/domains/${DOMAIN}/pap/policySet'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py
    sed -e "s@^ACCESS_CONTROL_MAGIC_KEY = None@ACCESS_CONTROL_MAGIC_KEY = '${MAGIC_KEY}'@" -i /opt/fi-ware-idm/horizon/openstack_dashboard/local/local_settings.py

    # Parse value into apache configuration

    sed -i /etc/apache2/sites-available/idm.conf \
        -e "s|IDM_KEYROCK_HOSTNAME|${IDM_KEYROCK_HOSTNAME}|g"

    _data_provision

    chown www-data:www-data /opt/fi-ware-idm/horizon/openstack_dashboard/local/.secret_key_store

    # Start container back

    start_horizon

    wait "${_waitpid}"
else
    exec "$@"
fi
