#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

    cat << EOF | debconf-set-selections
mysql-server-${MYSQL_UBUNTU_VERSION} mysql-server/root_password password ${DBROOTPW}
mysql-server-${MYSQL_UBUNTU_VERSION} mysql-server/root_password_again password ${DBROOTPW}
mysql-server-${MYSQL_UBUNTU_VERSION} mysql-server/root_password seen true
mysql-server-${MYSQL_UBUNTU_VERSION} mysql-server/root_password_again seen true
EOF
