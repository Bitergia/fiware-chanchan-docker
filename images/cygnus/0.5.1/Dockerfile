# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Bitergia <fiware-testing@bitergia.com>

ENV DEBIAN_FRONTEND noninteractive

ENV CYGNUS_USER="cygnus"
ENV GIT_REV_CYGNUS=release-0.5.1
ENV CYGNUS_CONNECTORS_HOME="fiware-connectors"

RUN adduser --disabled-password --gecos "${CYGNUS_USER}" ${CYGNUS_USER}

WORKDIR /home/${CYGNUS_USER}

ENV FLUME_VERSION="1.4.0"
ENV TGZ="apache-flume-${FLUME_VERSION}-bin.tar.gz"
ENV UNPACKED="apache-flume-${FLUME_VERSION}-bin"
ENV URL="http://archive.apache.org/dist/flume/${FLUME_VERSION}/${TGZ}"
ENV APACHE_FLUME_HOME="APACHE_FLUME_HOME"

# Apache Flume
RUN curl --remote-name --location --insecure --silent --show-error "${URL}" && \
    tar zxf "${TGZ}" && \
    mv "${UNPACKED}" "${APACHE_FLUME_HOME}" && \
    rm -f "${TGZ}" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus/lib" && \
    mkdir -p "${APACHE_FLUME_HOME}/plugins.d/cygnus/libext"

RUN apt-get update && \
    apt-get -y install --no-install-recommends openjdk-7-jdk && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# FIWARE Connectors for Apache Flume
# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends git git-core maven && \
    git clone https://github.com/telefonicaid/fiware-connectors.git ${CYGNUS_CONNECTORS_HOME} && \
    cd ${CYGNUS_CONNECTORS_HOME} && \
    git checkout ${GIT_REV_CYGNUS} && \
    cd flume && \
    mvn clean compile exec:exec assembly:single && \
    cd .. && \
    cp flume/target/cygnus-*-jar-with-dependencies.jar ../${APACHE_FLUME_HOME}/plugins.d/cygnus/lib && \
    cp /root/.m2/repository/com/googlecode/json-simple/json-simple/1.1/json-simple-1.1.jar ../${APACHE_FLUME_HOME}/plugins.d/cygnus/libext/ && \
    cd .. && \
    rm -fr ${CYGNUS_CONNECTORS_HOME} && \
    apt-get -y remove --purge maven git git-core && \
    apt-get -y autoremove --purge && \
    rm -rf /root/.m2 && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# Configure CKAN
COPY cygnus.conf ${APACHE_FLUME_HOME}/conf/cygnus.conf

RUN chown -R ${CYGNUS_USER}:${CYGNUS_USER} ${APACHE_FLUME_HOME}

# Configure service start/stop
COPY cygnus.default /etc/default/cygnus
COPY cygnus.init /etc/init.d/cygnus
RUN sed -i /etc/default/cygnus \
     -e "s|^CYGNUS_HOME=.*$|CYGNUS_HOME=/home/${CYGNUS_USER}/${APACHE_FLUME_HOME}|" \
     -e "s/^CYGNUS_USER=.*$/CYGNUS_USER='${CYGNUS_USER}'/" \
     -e "s/^CYGNUS_GROUP=.*$/CYGNUS_GROUP='${CYGNUS_USER}'/" && \
    update-rc.d cygnus defaults 90 90

COPY docker-entrypoint.sh /
ADD https://raw.githubusercontent.com/Bitergia/docker/master/utils/entrypoint-common.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
RUN touch /subscribe-to-orion

### Exposed ports
# - Cygnus notifications are received on this ports
EXPOSE 5001
EXPOSE 5002
EXPOSE 5050
EXPOSE 6001
