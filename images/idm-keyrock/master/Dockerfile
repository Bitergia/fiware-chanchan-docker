# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM ubuntu:14.04
MAINTAINER Bitergia <fiware-testing@bitergia.com>

ENV WORKON_HOME /opt/virtualenvs
ENV KEYROCK_HOME /opt/fiware-idm
ENV GIT_URL_KEYROCK https://github.com/ging/fiware-idm
ENV GIT_URL_KEYSTONE https://github.com/ging/keystone
ENV GIT_URL_HORIZON https://github.com/ging/horizon
ENV GIT_REV_KEYROCK master
ENV GIT_REV_KEYSTONE development
ENV GIT_REV_HORIZON development
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD no

WORKDIR ${KEYROCK_HOME}
RUN mkdir -p ${WORKON_HOME}

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends\
            autoconf \
            bash-completion \
            build-essential \
            ca-certificates \
            curl \
            gcc \
            git \
            libffi-dev \
            libjpeg8-dev \
            libldap2-dev \
            libmysqlclient-dev \
            libsasl2-dev \
            libsqlite3-dev \
            libssl-dev \
            libxml2-dev \
            libxslt1-dev \
            python-dev \
            python-mysqldb \
            python-setuptools \
            python-virtualenv \
            sqlite3 \
            virtualenvwrapper \
            && \

    # clone git repo
    git clone ${GIT_URL_KEYROCK} ${KEYROCK_HOME} && \
    cd ${KEYROCK_HOME} && \
    git checkout ${GIT_REV_KEYROCK} && \
    sed -e "/^        lrun('git checkout tags\/keyrock-{0}'.format(version))/d" \
        -i deployment/keystone.py && \
    sed -e "/^        lrun('git checkout tags\/keyrock-{0}'.format(version))/d" \
        -i deployment/horizon.py && \

    # configure fabric
    cp conf/settings.py.example conf/settings.py && \
    bash -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    mkvirtualenv idm_tools && \
    pip install -r requirements.txt" && \

    # install keystone
    git clone --branch ${GIT_REV_KEYSTONE} ${GIT_URL_KEYSTONE} ${KEYROCK_HOME}/keystone && \
    bash -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab keystone.install" && \

    # install horizon
    git clone --branch ${GIT_REV_HORIZON} ${GIT_URL_HORIZON} ${KEYROCK_HOME}/horizon && \
    bash -c "apt-get update && \
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab horizon.install &&\
    cd horizon && \
    tools/with_venv.sh python manage.py collectstatic --noinput && \
    tools/with_venv.sh python manage.py compress --force" && \
    apt-get -y install --no-install-recommends apache2 libapache2-mod-wsgi ssl-cert && \

    # cleanup image
    apt-get clean && \
    apt-get autoremove --purge -y && \
    find /var/lib/apt/lists -type f -delete && \
    rm -rf /root/.cache /root/.distlib

# configure apache
COPY idm.conf /opt/idm.conf
RUN mv /opt/idm.conf /etc/apache2/sites-available/idm.conf && \
    a2enmod wsgi ssl && \
    a2dissite 000-default && \
    a2ensite idm && \
    chown www-data:www-data ${KEYROCK_HOME}/horizon/openstack_dashboard/local && \
    mkdir -p ${KEYROCK_HOME}/horizon/static && \
    chown www-data:www-data ${KEYROCK_HOME}/horizon/static && \
    chown -R www-data:www-data ${KEYROCK_HOME}/horizon/media

COPY default_provision.py ${KEYROCK_HOME}/deployment/default_provision.py
COPY params-config.py ${KEYROCK_HOME}/keystone/params-config.py
COPY access_control_sync.py ${KEYROCK_HOME}/deployment/access_control_sync.py
COPY access_control_xacml.py ${KEYROCK_HOME}/horizon/access_control_xacml.py

RUN touch /initialize-provision && \
    touch /initialize-domain-request

COPY docker-entrypoint.sh /
ADD https://raw.githubusercontent.com/Bitergia/docker/master/utils/entrypoint-common.sh /
RUN chmod 755 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

### Exposed ports
# - Keystone
EXPOSE 5000
# - Horizon (HTTPS)
EXPOSE 443
