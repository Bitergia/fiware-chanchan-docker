#!/bin/bash

# server hostname
export HOSTNAME="$(hostname -f)"

# define this when the IP can not be obtained from the network interface configuration
export PUBLIC_IP=""

# mysql version
export MYSQL_UBUNTU_VERSION=5.5

export DEPLOY_USER=cygnus
export DEPLOY_USER_DIR=/home/${DEPLOY_USER}
export SCRIPTS_DIR=${DEPLOY_USER_DIR}/scripts

# default password for mysql root user
export ROOT_DBPASSWD="rootpw"
export DBROOTPW=${ROOT_DBPASSWD:-rootpw}
