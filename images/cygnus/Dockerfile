# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alvaro del Castillo <acs@bitergia.com>

ENV VERSION="1.4.0"
ENV CYGNUS_HOSTNAME="localhost"
ENV CYGNUS_USER="cygnus"
ENV CYGNUS_CONNECTORS_HOME="fiware-connectors"
ENV APACHE_FLUME_HOME="APACHE_FLUME_HOME"
ENV CKAN_API_KEY="44f762b2-978a-40ca-9dfc-1a8ec8855599"
ENV DEBIAN_FRONTEND noninteractive
ENV GIT_REV_CYGNUS=c797a60dabbd0bfc5e90c83efa9c15fed1bc1bd4

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        bash \
        git git-core \
        tree ccze \
        openjdk-7-jdk maven \
        python && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete


# create user ${CYGNUS_USER}
RUN adduser --disabled-password --gecos "${CYGNUS_USER}" ${CYGNUS_USER}
RUN adduser ${CYGNUS_USER} sudo

# sudo without password
# create the file if not exists
RUN touch /etc/sudoers.d/${CYGNUS_USER}
RUN sed -i -e "\$a${CYGNUS_USER} ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/${CYGNUS_USER}
RUN chmod 0440 /etc/sudoers.d/${CYGNUS_USER}
RUN chmod 0755 /home/${CYGNUS_USER}

USER ${CYGNUS_USER}
WORKDIR /home/${CYGNUS_USER}

ENV TGZ="apache-flume-${VERSION}-bin.tar.gz"
ENV UNPACKED="apache-flume-${VERSION}-bin"
ENV URL="http://archive.apache.org/dist/flume/${VERSION}/${TGZ}"

# Apache Flume
RUN if [ -d "${APACHE_FLUME_HOME}" ]; then rm -rf "${APACHE_FLUME_HOME}"; fi && \
    echo "Downloading ${TGZ}" && \
    curl --remote-name --location --insecure --silent --show-error "${URL}" && \
    echo "Unpacking ${TGZ}" && \
    tar zxf "${TGZ}" && \
    mv "${UNPACKED}" "${APACHE_FLUME_HOME}" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus/lib" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus/libext"

# FIWARE Connectors for Apache Flume
RUN if [ -d "${CYGNUS_CONNECTORS_HOME}" ]; then rm -rf "${CYGNUS_CONNECTORS_HOME}"; fi && \
    git clone https://github.com/telefonicaid/fiware-connectors.git ${CYGNUS_CONNECTORS_HOME} && \
    cd ${CYGNUS_CONNECTORS_HOME} && \
    if [ "${GIT_REV_CYGNUS}" != "master" ]; then git checkout ${GIT_REV_CYGNUS}; fi && \
    cd flume && \
    mvn clean compile exec:exec assembly:single && \
    cd .. && \
    cp flume/target/cygnus-*-jar-with-dependencies.jar ../${APACHE_FLUME_HOME}/plugins.d/cygnus/lib && \
    cp ../.m2/repository/com/googlecode/json-simple/json-simple/1.1/json-simple-1.1.jar ../${APACHE_FLUME_HOME}/plugins.d/cygnus/libext/

# Configure CKAN
ADD cygnus.conf ${APACHE_FLUME_HOME}/conf/cygnus.conf
RUN sed -i ${APACHE_FLUME_HOME}/conf/cygnus.conf -e "s/api_key = API_KEY/api_key = ${CKAN_API_KEY}/g"
# Subscribe to Orion to receive notifications
ADD notify-contex-cygnus.sh /home/${CYGNUS_USER}/notify-contex-cygnus.sh
RUN echo "Configure and execute /home/${CYGNUS_USER}/notify-contex-cygnus.sh to subscribe Cygnus to Orion"

USER root
# Configure service start/stop
ADD cygnus.default /etc/default/cygnus
ADD cygnus.init /etc/init.d/cygnus
RUN sed -i /etc/default/cygnus \
     -e "s|^CYGNUS_HOME=.*$|CYGNUS_HOME=/home/${CYGNUS_USER}/${APACHE_FLUME_HOME}|" \
     -e "s/^CYGNUS_USER=.*$/CYGNUS_USER='${CYGNUS_USER}'/" \
     -e "s/^CYGNUS_GROUP=.*$/CYGNUS_GROUP='${CYGNUS_USER}'/" && \
    update-rc.d cygnus defaults 90 90 && \
    service cygnus restart