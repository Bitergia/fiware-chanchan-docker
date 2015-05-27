# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alvaro del Castillo <acs@bitergia.com>

ENV WORKON_HOME /home/chanchan
ENV DEBIAN_FRONTEND noninteractive
ENV GIT_REV_ORION_PROXYCOAP 749e22376664dd3adae17492090e58882d3b28a7
ENV GIT_REV_ORION 1e8518d6ebe1a49695c85d4535ae32bf3279927e

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends\
        bash \
        git git-core \
        tree ccze \
        libboost-all-dev libcurlpp-dev libmicrohttpd-dev mongodb-dev cmake libcurl4-openssl-dev clang-3.5 libcunit1-dev mongodb g++ make \
        && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete
# Fix clang issues
RUN [ -e /usr/bin/clang ] || ln -s /usr/bin/clang-3.5 /usr/bin/clang && \
    [ -e /usr/bin/clang++ ] || ln -s /usr/bin/clang++-3.5 /usr/bin/clang++

# create user chanchan
RUN adduser --disabled-password --gecos "chanchan" chanchan
RUN adduser chanchan sudo

# sudo without password
# create the file if not exists
RUN touch /etc/sudoers.d/chanchan
RUN sed -i -e "\$achanchan ALL=(ALL) NOPASSWD:ALL" /etc/sudoers.d/chanchan
RUN chmod 0440 /etc/sudoers.d/chanchan
RUN chmod 0755 /home/chanchan

WORKDIR ${WORKON_HOME}

# proxycoap
RUN rm -rf cantcoap
RUN git clone https://github.com/staropram/cantcoap && \
    cd cantcoap && \
    if [ "${GIT_REV_ORION_PROXYCOAP}" != "master" ]; then git checkout ${GIT_REV_ORION_PROXYCOAP}; fi && \
    make && \
    sudo cp cantcoap.h dbg.h nethelper.h /usr/local/include && \
    sudo cp libcantcoap.a /usr/local/lib

# orion
RUN rm -rf "fiware-orion"


# clone repository
RUN git clone https://github.com/telefonicaid/fiware-orion && \
    cd fiware-orion && \
    if [ "${GIT_REV_ORION}" != "master" ]; then git checkout ${GIT_REV_ORION}; fi && \
    sed -e 's/"Ubuntu_14.04.1_LTS")/"Ubuntu_14.04.1_LTS" OR (${DISTRO} STREQUAL "Ubuntu_14.04.2_LTS"))/g' -i src/app/contextBroker/CMakeLists.txt && \
    sed -e 's/"Ubuntu_14.04.1_LTS")/"Ubuntu_14.04.1_LTS" OR (${DISTRO} STREQUAL "Ubuntu_14.04.2_LTS"))/g' -i src/app/proxyCoap/CMakeLists.txt && \
    INSTALL_DIR=${WORKON_HOME} make install