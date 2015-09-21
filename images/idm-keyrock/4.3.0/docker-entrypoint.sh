#!/bin/bash

source /entrypoint-common.sh

declare DOMAIN=''

# Funtion that checks if the domain has been already created at Authzforce

function check_domain () {

    if [ $# -lt 2 ] ; then
        echo "check_host_port: missing parameters."
        echo "Usage: check_host_port <host> <port> [max-tries]"
        exit 1
    fi

    local _host=$1
    local _port=$2
    local CURL=$( which curl )

    if [ ! -e "${CURL}" ] ; then
        echo "Unable to find 'curl' command."
        exit 1
    fi

    if [ -e /initialize-domain-request ] ; then

        # Creates the domain

        ${CURL} -s \
                --request POST \
                --header "Content-Type: application/xml;charset=UTF-8" \
                --data '<?xml version="1.0" encoding="UTF-8"?><taz:properties xmlns:taz="http://thalesgroup.com/authz/model/3.0/resource"><name>MyDomain</name><description>This is my domain.</description></taz:properties>' \
                --header "Accept: application/xml" \
                --output /dev/null \
                http://${_host}:${_port}/authzforce/domains

    fi

    DOMAIN=$( ${CURL} -s --request GET http://${_host}:${_port}/authzforce/domains | awk '/href/{print $NF}' | cut -d '"' -f2 )
    if [ -z "${DOMAIN}" ] ; then
        echo "Unable to find domain."
        exit 1
    else
        echo "Domain: $DOMAIN"
        if [ -e /initialize-domain-request ] ; then
            rm /initialize-domain-request
            touch /config/domain-ready
        fi
    fi
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

        if check_file ${PROVISION_FILE} 10 ; then
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

    check_var AUTHZFORCE_HOSTNAME authzforce
    check_var AUTHZFORCE_PORT 8080
    check_var IDM_KEYROCK_HOSTNAME idm
    check_var IDM_KEYROCK_PORT 443
    check_var MAGIC_KEY daf26216c5434a0a80f392ed9165b3b4
    check_var WORKON_HOME /opt/virtualenvs
    check_var APP_NAME "FIWAREdevGuide"
    check_var KEYSTONE_DB /opt/fi-ware-idm/keystone/keystone.db
    check_var CONFIG_FILE /config/idm2chanchan.json
    check_var PROVISION_FILE /config/keystone_provision.py
    check_var KEYSTONE_VERBOSE no
    
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
