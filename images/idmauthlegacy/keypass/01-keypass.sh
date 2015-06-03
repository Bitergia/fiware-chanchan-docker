#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

service mysql start

# create database
cat <<EOF | mysql --user=root --password=${ROOT_DBPASSWD}
CREATE DATABASE ${KEYPASS_DBNAME};
CREATE USER ${KEYPASS_DBUSER}@localhost identified by '${KEYPASS_DBPASS}';
GRANT ALL PRIVILEGES ON ${KEYPASS_DBNAME}.* to ${KEYPASS_DBUSER}@localhost;
FLUSH PRIVILEGES;
EOF

# Load date in db
cd ${DEPLOY_USER_DIR}/${KEYPASS_HOME}
java -jar target/keypass-0.3.0.jar db migrate conf/config.yml

