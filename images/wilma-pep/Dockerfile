# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alberto Martín <alberto.martin@bitergia.com>

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

RUN git clone https://github.com/ging/fi-ware-pep-proxy.git fiware-pep-proxy && \
    cd fiware-pep-proxy && \
    npm install

# Configure PEP proxy

ADD config.js /home/bitergia/fiware-pep-proxy/config.js

# Retrieve domain

ADD config-domain.sh /home/bitergia/config-domain.sh
RUN chmod 755 /home/bitergia/config-domain.sh
ENTRYPOINT ["/home/bitergia/config-domain.sh"]
