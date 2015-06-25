#!/bin/bash
set -e

if find /var/lib/mysql -type d -prune -empty 2>&1 | grep -q "^/var/lib/mysql$" ; then
    # initialize
    if [ -z "${MYSQL_ROOT_PASSWORD}" ] ; then
	export MYSQL_ROOT_PASSWORD="bitergia"
	echo "MYSQL_ROOT_PASSWORD is not set.  Using default password '${MYSQL_ROOT_PASSWORD}'"

	# preseed
	cat <<EOF | debconf-set-selections
mariadb-server-10.0 mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}
mariadb-server-10.0 mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}
mariadb-server-10.0 mysql-server/root_password seen true
mariadb-server-10.0 mysql-server/root_password_again seen true
EOF
    fi

    # let the package postinst take care of default database creation
    export DEBIAN_FRONTEND=noninteractive
    dpkg-reconfigure mariadb-server-${MARIADB_VERSION}

    # wait for server process before updating root user
    sleep 5

    # enable access from other hosts
    cat <<EOF | mysql -u root -p${MYSQL_ROOT_PASSWORD}
CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
FLUSH PRIVILEGES ;
EOF

    invoke-rc.d mysql stop
fi

exec /sbin/init
