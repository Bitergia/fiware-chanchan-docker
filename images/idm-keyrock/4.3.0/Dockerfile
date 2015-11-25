# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM ubuntu:14.04
MAINTAINER Alvaro del Castillo <acs@bitergia.com>, Alberto Martín <alberto.martin@bitergia.com>, David Muriel <dmuriel@bitergia.com>

ENV WORKON_HOME /opt/virtualenvs
ENV KEYROCK_HOME /opt/fi-ware-idm
ENV GIT_URL_KEYROCK https://github.com/ging/fi-ware-idm
RUN mkdir -p /opt/virtualenvs
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD no

COPY idm.conf /opt/idm.conf
WORKDIR /opt/fi-ware-idm

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends\
            curl \
            git \
            ca-certificates \
            bash-completion \
            python-dev \
            python-setuptools \
            build-essential \
            virtualenvwrapper \
            gcc \
            autoconf \
            python-virtualenv \
            libssl-dev \
            libffi-dev \
            libjpeg8-dev \
            libxml2-dev \
            libxslt1-dev \
            libsasl2-dev \
            libssl-dev \
            libldap2-dev \
            libffi-dev \
            libsqlite3-dev \
            libmysqlclient-dev \
            python-mysqldb \
            libsqlite3-dev \
            sqlite3 \
            && \
    # clone git repo
    git clone ${GIT_URL_KEYROCK} ${KEYROCK_HOME} && \
    # configure fabric
    cp conf/settings.py.example conf/settings.py && \
    bash -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    mkvirtualenv idm_tools && \
    pip install -r requirements.txt" && \
    # install keystone
    bash -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab keystone.install" && \
    # install horizon
    bash -c "apt-get update && \
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab horizon.install" && \
    apt-get -y install --no-install-recommends apache2 libapache2-mod-wsgi ssl-cert && \
    mv /opt/idm.conf /etc/apache2/sites-available/idm.conf && \
    a2enmod wsgi ssl && \
    a2dissite 000-default && \
    a2ensite idm && \
    chown www-data:www-data ${KEYROCK_HOME}/horizon/openstack_dashboard/local && \
    mkdir -p ${KEYROCK_HOME}/horizon/static && \
    chown www-data:www-data ${KEYROCK_HOME}/horizon/static && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete && \
    rm -rf /root/.cache /root/.distlib

# Extract clientID and client-secret from database

COPY default_provision.py /opt/fi-ware-idm/deployment/default_provision.py
COPY params-config.py /opt/fi-ware-idm/keystone/params-config.py
COPY access_control_sync.py /opt/fi-ware-idm/deployment/access_control_sync.py
COPY access_control_xacml.py /opt/fi-ware-idm/horizon/access_control_xacml.py

RUN touch /initialize-provision && \
    touch /initialize-domain-request

# Authzforce domain configuration

COPY docker-entrypoint.sh /
ADD https://raw.githubusercontent.com/Bitergia/docker/master/utils/entrypoint-common.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

### Exposed ports
# - Keystone
EXPOSE 5000
# - Horizon (HTTPS)
EXPOSE 443
