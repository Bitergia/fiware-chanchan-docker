FROM bitergia/ubuntu-trusty

MAINTAINER David Muriel <dmuriel@bitergia.com>

ENV DEBIAN_FRONTEND noninteractive
ENV MARIADB_VERSION 5.5

RUN apt-get update && \
    apt-get -y install debconf-utils && \
    apt-get -y install mariadb-server && \
    sed -ri 's/^(bind-address|skip-networking)/;\1/' /etc/mysql/my.cnf && \
    apt-get -y autoremove --purge && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete && \
    rm -fr /var/lib/mysql/*

EXPOSE 3306

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
