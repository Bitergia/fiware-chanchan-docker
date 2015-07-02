# Copyright (C) 2015 Bitergia
# GPLv3 License

FROM bitergia/ubuntu-trusty:latest
MAINTAINER Alberto Martín <alberto.martin@bitergia.com>

ENV DEBIAN_FRONTEND noninteractive

# install APT dependencies
# Fix some issues with APT packages (fix initctl)
# See https://github.com/dotcloud/docker/issues/1024

RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl
RUN echo -e "#!/bin/sh\nexit 101\n" > /usr/sbin/policy-rc.d
RUN chmod +x /usr/sbin/policy-rc.d

RUN apt-get update && \
    apt-get -y install openjdk-7-jdk tomcat7 \
	    && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# Modify Tomcat init to detect PID without special permissions

RUN mv /etc/init.d/tomcat7 /etc/init.d/tomcat7.tmp
ADD tomcat7 /etc/init.d/
RUN chmod 755 /etc/init.d/tomcat7

EXPOSE 8080

# Restore initctl

RUN rm -f /usr/sbin/policy-rc.d
RUN rm -f /sbin/initctl
RUN dpkg-divert --local --rename --remove /sbin/initctl

RUN service tomcat7 stop
RUN service tomcat7 start

# download and install Authzforce (service starts Automatically)

RUN curl -O -L http://catalogue.fiware.org/sites/default/files/storage/enablers/authzforce_4.2.0-fiware_all.deb && \
    dpkg -i authzforce_4.2.0-fiware_all.deb
