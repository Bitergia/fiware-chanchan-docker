#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

MYSQL_SOCK="/var/run/mysqld/mysqld.sock"

idmrepo="https://github.com/ging/fi-ware-idm-deprecated.git"

service ssh start
service mysql start

# generate ssh keys
su - idm-source <<EOF
ssh-keygen -t rsa -b 4096 -f \${HOME}/.ssh/deploy -P ''
ssh-keyscan -H ${HOSTNAME} >> \${HOME}/.ssh/known_hosts
cat <<__EOF__ > \${HOME}/.ssh/config
Host ${HOSTNAME}
    User idm-deploy
    IdentityFile \${HOME}/.ssh/deploy
__EOF__
chmod 0600 \${HOME}/.ssh/config
EOF

cat /home/idm-source/.ssh/deploy.pub >> /home/idm-deploy/.ssh/authorized_keys
chown idm-deploy:idm-deploy /home/idm-deploy/.ssh/authorized_keys

su - idm-source <<EOF
cd fi-ware-idm
# upload configuration files to deploy
scp config/database.yml ${HOSTNAME}:fi-ware-idm/shared/config/
scp config/initializers/0fiware.rb ${HOSTNAME}:fi-ware-idm/shared/config/initializers/
scp config/initializers/thales.rb ${HOSTNAME}:fi-ware-idm/shared/config/initializers/
scp -r ${SCRIPTS_DIR}/patches/* ${HOSTNAME}:fi-ware-idm/shared/
# Do the deploy
REVISION=${GIT_REV_IDM} cap production deploy
EOF