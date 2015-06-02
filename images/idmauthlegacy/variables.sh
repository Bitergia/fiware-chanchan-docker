#!/bin/bash

# server hostname
export HOSTNAME="$(hostname -f)"

# define this when the IP can not be obtained from the network interface configuration
export PUBLIC_IP=""

# mysql version
export MYSQL_UBUNTU_VERSION=5.5

export DEPLOY_USER=bitergia
export DEPLOY_USER_DIR=/home/${DEPLOY_USER}
export SCRIPTS_DIR=${DEPLOY_USER_DIR}/scripts

### IDM related variables
export IDM_HOSTNAME="idm.${HOSTNAME}"
export IDM_URL="https://${IDM_HOSTNAME}"

# default password for mysql root user
export ROOT_DBPASSWD="rootpw"
export DBROOTPW=${ROOT_DBPASSWD:-rootpw}

# default user, password and name for production database
export IDM_DBNAME="idmdb"
export IDM_DBUSER="idmdbuser"
export IDM_DBPASS="idmdbpass"

### Orion PEP related variables
export ORION_PEP_USER="bitergia"
export ORION_PEP_HOME="fiware-orion-pep"

### Orion related variables
export KEYPASS_USER="bitergia"
export KEYPASS_HOME="fiware-keypass"
export KEYPASS_DBNAME="keypass"
export KEYPASS_DBUSER="keypass"
export KEYPASS_DBPASS="keypass"

## Revisions to use on git repos: v1.0
export GIT_REV_IDM=99c9591c8b547583946af08d2f4c77b1db6719fd
export GIT_REV_KEYPASS=431ea3c83d0ebc8809391f136e2b00954f0c014b

# user to register chanchan app on IDM
export CC_USER_NAME="Chanchan Admin"
export CC_EMAIL="chanchan@${IDM_HOSTNAME}"
export CC_PASS="ccadmin"

