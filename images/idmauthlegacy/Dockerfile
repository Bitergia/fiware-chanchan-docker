# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alvaro del Castillo <acs@bitergia.com>

ENV GIT_REV_IDM=99c9591c8b547583946af08d2f4c77b1db6719fd
ENV GIT_REV_KEYPASS=431ea3c83d0ebc8809391f136e2b00954f0c014b
ENV GIT_REV_ORION_PEP=6b80dfae6a0c06eeae66d716a9a3db69371b615b


ENV DEBIAN_FRONTEND noninteractive
ENV DEPLOY_USER bitergia
ENV DEPLOY_USER_DIR /home/${DEPLOY_USER}
ENV SCRIPTS_DIR ${DEPLOY_USER_DIR}/scripts


# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        bash \
        git git-core \
        tree ccze \
        psmisc \
        debconf-utils \
        build-essential openssl libreadline6 libreadline6-dev curl zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 \
        libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool \
        bison subversion pkg-config libmysqlclient-dev libreadline-dev \
        libxslt1-dev libcurl4-openssl-dev \
        apache2 libapache2-mod-passenger \
        imagemagick graphicsmagick libmagickwand-dev \
        sendmail-bin recode \
        ruby1.9.1 ruby1.9.1-dev bundler \
        openjdk-7-jdk maven && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete


# MySQL install and config and db creation
ADD variables.sh ${SCRIPTS_DIR}/variables.sh
ADD configure-mysql.sh ${SCRIPTS_DIR}/configure-mysql.sh
ADD create-idm-db.sh ${SCRIPTS_DIR}/create-idm-db.sh

# preseed debconf to set the mysql root password
RUN ${SCRIPTS_DIR}/configure-mysql.sh

RUN apt-get update && apt-get install -qy mysql-server

# Time to install Keypass
ADD keypass ${SCRIPTS_DIR}/keypass
ENV KEYPASS_HOME /home/${DEPLOY_USER}/fiware-keypass
RUN if [ -d "${KEYPASS_HOME}" ]; then rm -rf "${KEYPASS_HOME}"; fi && \
    git clone https://github.com/telefonicaid/fiware-keypass.git ${KEYPASS_HOME} && \
    cd ${KEYPASS_HOME} && \
    if [ "${GIT_REV_KEYPASS}" != "master" ]; then git checkout ${GIT_REV_KEYPASS}; fi && \
    mvn clean package
RUN ${SCRIPTS_DIR}/keypass/01-keypass.sh && \
    ${SCRIPTS_DIR}/keypass/02-config-keypass.sh && \
    ${SCRIPTS_DIR}/keypass/03-start-keypass.sh

# Setup, prepare deploy and deploy IDM KeyRock legacy (ruby based)
RUN ${SCRIPTS_DIR}/create-idm-db.sh
ADD setup-users.sh ${SCRIPTS_DIR}/setup-users.sh
RUN ${SCRIPTS_DIR}/setup-users.sh
ADD patches ${SCRIPTS_DIR}/patches

# IDM needs a javascript machine: nodejs. And ssh to deploy.
RUN apt-get update && apt-get install -qy ssh ssl-cert nodejs nodejs-legacy npm

ADD prepare-deploy.sh ${SCRIPTS_DIR}/prepare-deploy.sh
RUN ${SCRIPTS_DIR}/prepare-deploy.sh
ADD do-deploy.sh ${SCRIPTS_DIR}/do-deploy.sh
RUN ${SCRIPTS_DIR}/do-deploy.sh
ADD update_hosts.sh ${SCRIPTS_DIR}/update_hosts.sh
ADD check_docker.sh ${SCRIPTS_DIR}/check_docker.sh
ADD create-virtualhosts.sh ${SCRIPTS_DIR}/create-virtualhosts.sh
# IDM provision
ADD idm-provision ${SCRIPTS_DIR}/idm-provision
RUN ${SCRIPTS_DIR}/create-virtualhosts.sh && \
    a2enmod ssl && \
    service apache2 restart && \
    service mysql start && \
    ${SCRIPTS_DIR}/idm-provision/idm-provision-app.sh && \
    ${SCRIPTS_DIR}/keypass/03-start-keypass.sh && \
    ${SCRIPTS_DIR}/idm-provision/idm-provision-roles.sh


# enable modules, disable default site, restart service
RUN a2enmod ssl && a2enmod passenger && \
    a2dissite 000-default && \
    service apache2 restart