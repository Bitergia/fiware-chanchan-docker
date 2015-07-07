FROM bitergia/centos-6

MAINTAINER David Muriel <dmuriel@bitergia.com>

ENV NODE_VERSION v0.10.39

RUN curl -kOL https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz && \
    tar --strip-components 1 -xzf node-${NODE_VERSION}-linux-x64.tar.gz -C /usr/local/ && \
    rm -f node-${NODE_VERSION}-linux-x64.tar.gz

ENV IOTA_PATH /opt/iotagent-lwm2m
ENV IOTA_LOG_PATH /var/log/iotagent-lwm2m
ENV GIT_IOTA_VERSION 0.2.0
ENV IOTA_USER iota

RUN yum -y install git gcc gcc-c++ && \
    git clone https://github.com/telefonicaid/lightweightm2m-iotagent.git ${IOTA_PATH} && \
    cd ${IOTA_PATH} && \
    git checkout ${GIT_IOTA_VERSION} && \
    rm -rf node_modules && \
    npm install --production && \
    npm cache clear && \
    yum -y erase git perl perl-Error perl-Git perl-Module-Pluggable perl-Pod-Escapes perl-Pod-Simple perl-libs perl-version rsync gcc cloog-ppl cpp glibc-devel glibc-headers kernel-headers libgomp mpfr ppl gcc-c++ libstdc++-devel && \
    yum clean all && \
    rm -rf /tmp/* && \
    rm -rf /root/.node-gyp/* && \
    adduser --shell "/bin/bash" --home-dir ${IOTA_PATH} --comment "${IOTA_USER}" ${IOTA_USER} && \
    cp /etc/skel/.bash* ${IOTA_PATH}/ && \
    chown -R ${IOTA_USER}:${IOTA_USER} ${IOTA_PATH}

COPY config.js ${IOTA_PATH}/config.js
RUN chown ${IOTA_USER}:${IOTA_USER} ${IOTA_PATH}/config.js

RUN cp ${IOTA_PATH}/rpm/SOURCES/etc/init.d/iotagent-lwm2m /etc/init.d/iotagent-lwm2m && \
    sed -i /etc/init.d/iotagent-lwm2m -e "/^IOTA_PATH=/a IOTA_USER=${IOTA_USER}" -e 's/su $IOTA_USER -p /su - $IOTA_USER /' && \
    chkconfig iotagent-lwm2m on && \
    mkdir -p ${IOTA_LOG_PATH} && \
    chown -R ${IOTA_USER}:${IOTA_USER} ${IOTA_LOG_PATH} && \
    chmod g+s ${IOTA_LOG_PATH}

COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
