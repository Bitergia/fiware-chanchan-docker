#!/bin/bash

function _setup_init () {
    sudo cp ${SCRIPTS_PATH}/keypass/keypass.default ${DEFAULT}
    sudo sed -i ${DEFAULT} \
	 -e "s|^KEYPASS_HOME=.*$|KEYPASS_HOME=${HOME}/${KEYPASS_HOME}|" \
	 -e "s/^KEYPASS_USER=.*$/KEYPASS_USER='${KEYPASS_USER}'/" \
	 -e "s/^KEYPASS_GROUP=.*$/KEYPASS_GROUP='${KEYPASS_USER}'/"
    sudo cp ${SCRIPTS_PATH}/keypass/keypass.init.${DIST_TYPE} /etc/init.d/keypass
    sudo chmod +x /etc/init.d/keypass
}

case "${DIST_TYPE}" in
    "debian")
	DEFAULT=/etc/default/keypass
	_setup_init
	sudo update-rc.d keypass defaults 90 90
	sudo service keypass restart
	;;
    "redhat")
	DEFAULT=/etc/sysconfig/keypass
	_setup_init
	sudo chkconfig keypass on
	sudo service keypass restart
	;;
    *)
	exit 1
	;;
esac
