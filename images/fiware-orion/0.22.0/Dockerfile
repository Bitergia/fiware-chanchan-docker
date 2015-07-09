FROM bitergia/centos-6:latest

MAINTAINER David Muriel <dmuriel@bitergia.com>

ENV ORION_USER orion
ENV GIT_REV_ORION_PROXYCOAP 749e22376664dd3adae17492090e58882d3b28a7
ENV GIT_REV_ORION 0.22.0

RUN adduser --comment "${ORION_USER}" ${ORION_USER}

WORKDIR /opt

RUN yum -y install git make cmake gcc-c++ scons libmicrohttpd-devel boost-devel libcurl-devel clang CUnit-devel && \
    curl -kOL https://github.com/mongodb/mongo-cxx-driver/archive/legacy-1.0.2.tar.gz && \
    tar xfz legacy-1.0.2.tar.gz && \
    cd mongo-cxx-driver-legacy-1.0.2 && \
    scons install --prefix=/usr/local && \
    cd /opt && \
    rm -rf legacy-1.0.2.tar.gz mongo-cxx-driver-legacy-1.0.2 && \
    git clone https://github.com/staropram/cantcoap && \
    cd cantcoap && \
    git checkout ${GIT_REV_ORION_PROXYCOAP} && \
    make && \
    cp cantcoap.h dbg.h nethelper.h /usr/local/include && \
    cp libcantcoap.a /usr/local/lib && \
    cd /opt && \
    rm -rf /opt/cantcoap && \
    git clone https://github.com/telefonicaid/fiware-orion && \
    cd fiware-orion && \
    git checkout ${GIT_REV_ORION} && \
    make && \
    make install && \
    strip /usr/bin/contextBroker && \
    strip /usr/bin/proxyCoap && \
    mkdir -p /var/log/contextBroker && \
    mkdir -p /var/run/contextBroker && \
    chown ${ORION_USER} /var/log/contextBroker && \
    chown ${ORION_USER} /var/run/contextBroker && \
    install -m 0755 etc/init.d/contextBroker.centos /etc/init.d/contextBroker && \
    install -m 0644 etc/config/contextBroker /etc/sysconfig/contextBroker && \
    chkconfig contextBroker on && \
    cd /opt && \
    rm -rf /opt/fiware-orion && \
    yum -y erase git perl rsync \
	cmake libarchive \
	gcc-c++ cloog-ppl cpp gcc glibc-devel glibc-headers kernel-headers libgomp libstdc++-devel mpfr ppl \
	scons libmicrohttpd-devel boost-devel libcurl-devel \
	clang llvm llvm-libs \
	CUnit-devel CUnit pkgconfig \
	autoconf automake m4 libidn-devel && \
    yum clean all && \
    rm -f /usr/local/lib/libcantcoap.a /usr/local/lib/libmongoclient.a

WORKDIR /

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

### Exposed ports
# - Orion
EXPOSE 10026
