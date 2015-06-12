FROM bitergia/centos-6

MAINTAINER David Muriel <dmuriel@bitergia.com>

ADD mongodb-org-3.0.repo /etc/yum.repos.d/

RUN yum install -y mongodb-org && \
    yum clean all && \
    chkconfig mongod on && \
    sed -e 's/^bind_ip/#bind_ip/g' -i /etc/mongod.conf

EXPOSE 27017

