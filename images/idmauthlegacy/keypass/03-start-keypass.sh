#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

function _setup_init () {
    sudo cp ${SCRIPTS_DIR}/keypass/keypass.default ${DEFAULT}
    sudo sed -i ${DEFAULT} \
        -e "s|^KEYPASS_HOME=.*$|KEYPASS_HOME=${DEPLOY_USER_DIR}/${KEYPASS_HOME}|" \
        -e "s/^KEYPASS_USER=.*$/KEYPASS_USER='${KEYPASS_USER}'/" \
        -e "s/^KEYPASS_GROUP=.*$/KEYPASS_GROUP='${KEYPASS_USER}'/"
    sudo cp ${SCRIPTS_DIR}/keypass/keypass.init.debian /etc/init.d/keypass
    sudo chmod +x /etc/init.d/keypass
}

DEFAULT=/etc/default/keypass
_setup_init
sudo update-rc.d keypass defaults 90 90
# sudo service keypass restart
# During docker image creation, start manually
java -jar ${DEPLOY_USER_DIR}/${KEYPASS_HOME}/target/keypass-0.3.0.jar server ${DEPLOY_USER_DIR}/${KEYPASS_HOME}/conf/config.yml &