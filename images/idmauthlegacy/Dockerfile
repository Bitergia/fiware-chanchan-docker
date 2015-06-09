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

# Orion PEP
ADD orion-pep ${SCRIPTS_DIR}/orion-pep
ENV ORION_PEP_HOME /home/${DEPLOY_USER}/fiware-orion-pep
# user to register chanchan app on IDM
ENV IDM_HOSTNAME=localhost
ENV CC_EMAIL=chanchan@${IDM_HOSTNAME}
ENV CC_PASS=ccadmin
ENV ORION_HOSTNAME=orion
ENV ORION_PORT=1026
# Configure Orion PEP: first approach. Should be changed to the specific config.
RUN if [ -d "${ORION_PEP_HOME}" ]; then rm -rf "${ORION_PEP_HOME}"; fi && \
    git clone https://github.com/telefonicaid/fiware-orion-pep.git ${ORION_PEP_HOME} && \
    cd ${ORION_PEP_HOME} && \
    if [ "${GIT_REV_ORION_PEP}" != "master" ]; then git checkout ${GIT_REV_ORION_PEP}; fi && \
    npm install && \
    npm install production
RUN cp ${SCRIPTS_DIR}/orion-pep/config.js ${ORION_PEP_HOME}/config.js
RUN sed -i ${ORION_PEP_HOME}/config.js \
    -e  "s/module: 'keystone'/module: 'idm'/"\
    -e  "s/user: 'pepproxy'/user: '${CC_EMAIL}'/" \
    -e  "s/password: 'pepproxy'/password: '${CC_PASS}'/"\
    -e  "s/        protocol: 'http'/        protocol: 'https'/"\
    -e  "/domainName: 'Default',/ d"\
    -e  "/retries: 5,/ d"\
    -e  "s/        host: 'localhost'/        host: '${ORION_HOSTNAME}'/"\
    -e  "s/        host: 'idmhost'/        host: '${IDM_HOSTNAME}'/"\
    -e  "s/port: 5000/port: 443/"\
    -e  "s/port: 10026/port: ${ORION_PORT}/"\
    -e  "s/path: '\/v3\/role_assignments'/path: '\/user'/"\
    -e  "s/authPath: '\/v3\/auth\/tokens'/authPath: '\/oauth2\/authorize'/"\
    -e  "s/config.logLevel = 'FATAL'/config.logLevel = 'DEBUG'/"\
    -e  "s/config.componentName = 'orion'/config.componentName = 'contextbroker'/"\
    -e  "s/config.resourceNamePrefix = 'fiware:'/config.resourceNamePrefix = 'frn:'/"

# patch for Orion requests without headers
RUN sed -i ${ORION_PEP_HOME}/lib/fiware-orion-pep.js \
    -e "/delete options.headers\['content-length'\];/a\  delete options.headers['fiware-service']; \n\ delete options.headers['fiware-servicepath'];"

RUN sudo cp ${SCRIPTS_DIR}/orion-pep/orion-pep.default /etc/default/orion-pep && \
    sudo sed -i /etc/default/orion-pep \
        -e "s|^ORION_PEP_HOME=.*$|ORION_PEP_HOME=${ORION_PEP_HOME}|" \
        -e "s/^ORION_PEP_USER=.*$/ORION_PEP_USER='${DEPLOY_USER}'/" \
        -e "s/^ORION_PEP_GROUP=.*$/ORION_PEP_GROUP='${DEPLOY_USER}'/" && \
    sudo cp ${SCRIPTS_DIR}/orion-pep/orion-pep.init.debian /etc/init.d/orion-pep && \
    sudo chmod +x /etc/init.d/orion-pep && \
    sudo update-rc.d orion-pep defaults 90 90
RUN sudo service orion-pep restart

# Shared config to use the idmauthlegacy node
RUN mkdir /config && \
    cp -a /tmp/appoauth.txt /config && \
    echo `hostname` > /config/idm_host_docker_image
VOLUME /config