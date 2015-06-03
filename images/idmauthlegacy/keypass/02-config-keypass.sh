#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

# edit config
sed -i ${DEPLOY_USER_DIR}/${KEYPASS_HOME}/conf/config.yml \
    -e "s/8080/7070/"  \
    -e "s/8081/7071/" \
    -e "s/level: INFO/level: DEBUG/" \
    -e "s|currentLogFilename: ./log/|currentLogFilename: /var/log/keypass/|" \
    -e "s|archivedLogFilenamePattern: ./log/|archivedLogFilenamePattern: /var/log/keypass/|"
