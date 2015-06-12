FROM bitergia/centos-6

MAINTAINER David Muriel <dmuriel@bitergia.com>

WORKDIR /root

RUN curl -kOL https://forge.fiware.org/docman/view.php/49/5159/iot-agent-mqtt.tgz && \
    tar zxvf iot-agent-mqtt.tgz && \
    yum localinstall -y iot-agent-base*.rpm && \
    yum localinstall -y iot-agent-ul*.rpm && \
    rm -f iot-agent-mqtt.tgz && \
    yum clean all && \
    chkconfig iotagent on

COPY config.json /etc/iot/
