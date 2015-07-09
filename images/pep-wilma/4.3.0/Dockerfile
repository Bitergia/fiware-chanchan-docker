# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alberto Martín <alberto.martin@bitergia.com>

ENV WILMA_HOME /opt/fi-ware-pep-proxy
ENV DEBIAN_FRONTEND noninteractive

# Installing nodeJS

RUN curl -sL https://deb.nodesource.com/setup | sudo bash -

# install APT dependencies

RUN apt-get update && \
    apt-get -y install nodejs git python make gcc build-essential \
	    && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# download and install Authzforce (service starts Automatically)

RUN git clone https://github.com/ging/fi-ware-pep-proxy.git /opt/fi-ware-pep-proxy && \
    cd /opt/fi-ware-pep-proxy && \
    git checkout 85df40e376311beed51d1c21104414c8c3c9b2bf && \
    npm install

WORKDIR /opt/fi-ware-pep-proxy

# Install forever to make PEP run at Startup

RUN npm install forever --global

# Configure PEP proxy

ADD config.js ${WILMA_HOME}/config.js

COPY wilmapep.conf /etc/init/wilmapep.conf

# Retrieve domain

ADD config-domain.sh /opt/scripts/config-domain.sh
RUN chmod 755 /opt/scripts/config-domain.sh
ENTRYPOINT ["/opt/scripts/config-domain.sh"]

### Exposed ports
# - Wilma PEP
EXPOSE 1026
