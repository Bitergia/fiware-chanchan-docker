#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

## create the needed users
# idm-deploy
adduser --disabled-password --gecos "idm deploy" idm-deploy
adduser idm-source sudo
# idm-source
adduser --disabled-password --gecos "idm source" idm-source


## configure idm-deploy
su - idm-deploy <<EOF
chmod 0755 \${HOME}
mkdir -p \${HOME}/.ssh
chmod 0700 \${HOME}/.ssh
mkdir -p \${HOME}/fi-ware-idm/shared/config
mkdir -p \${HOME}/fi-ware-idm/shared/config/initializers
EOF

## configure idm-source
# allow passwordless sudo
cat <<EOF > /etc/sudoers.d/idm-source
idm-source ALL=(ALL) NOPASSWD:ALL
EOF
chmod 0440 /etc/sudoers.d/idm-source