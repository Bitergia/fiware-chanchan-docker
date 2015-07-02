#!/bin/bash

source ${SCRIPTS_DIR}/variables.sh

# User root with access from other containers
echo "CREATE USER 'root'@'%' IDENTIFIED BY 'rootpw'" | mysql -u root --password="${DBROOTPW}"
echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION" | mysql -u root --password="${DBROOTPW}"
echo "flush privileges" | mysql -u root --password="${DBROOTPW}"
