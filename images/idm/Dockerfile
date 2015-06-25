FROM bitergia/ubuntu-trusty:latest

ENV WORKON_HOME /opt/virtualenvs
ENV KEYROCK_HOME /opt/fi-ware-idm
RUN mkdir -p /opt/virtualenvs
ENV DEBIAN_FRONTEND noninteractive
ENV INITRD no

# install dependencies
RUN apt-get update && \
    apt-get -y install --no-install-recommends\
    	    git \
	    ca-certificates \
	    bash-completion \
	    python-dev \
	    python-setuptools \
	    build-essential \
	    virtualenvwrapper \
	    gcc \
	    autoconf \
	    python-virtualenv \
	    libssl-dev \
	    libffi-dev \
	    libjpeg8-dev \
	    libxml2-dev \
	    libxslt1-dev \
	    libsasl2-dev \
	    libssl-dev \
	    libldap2-dev \
	    libffi-dev \
	    libsqlite3-dev \
	    libmysqlclient-dev \
	    python-mysqldb \
	    libsqlite3-dev \
            sqlite3 \
	    && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

# clone git repo
#RUN git clone https://github.com/ging/fi-ware-idm /opt/fi-ware-idm
RUN git clone https://github.com/ging/fi-ware-idm /opt/fi-ware-idm && \
    mv /opt/fi-ware-idm/deployment/keystone.py /opt/fi-ware-idm/deployment/keystone.py.bkp
COPY keystone.py /opt/fi-ware-idm/deployment/keystone.py
WORKDIR /opt/fi-ware-idm

# configure fabric
RUN cp conf/settings.py.example conf/settings.py
RUN bash -c "source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    mkvirtualenv idm_tools && \
    pip install -r requirements.txt && pip install -I oslo.i18n==1.7 "

#RUN sed -e "s/env.run('sudo apt-get install {0}'.format(dependencies))/env.run('sudo apt-get -y install {0}'.format(dependencies))/g" -i deployment/horizon.py

# install keystone
RUN bash -c "apt-get update && \
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab localhost keystone.install && \
    fab localhost keystone.database_create && \
    fab localhost keystone.set_up_as_service && \
    (fab localhost keystone.dev_server &) && \
    sleep 10 && \
    fab localhost keystone.populate && \
    fab localhost keystone.test_data && \
    (ps axf | grep -i keystone-all | grep -v grep | cut -d ' ' -f 1 | xargs kill -s TERM) && \
    sed -e \"s/^start on .*$/start on runlevel [2345]/g\" -i /etc/init/keystone_idm.conf && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete"

# install horizon
RUN bash -c "apt-get update && \
    source /usr/share/virtualenvwrapper/virtualenvwrapper.sh && \
    workon idm_tools && \
    fab localhost horizon.install && \
    /opt/fi-ware-idm/horizon/tools/with_venv.sh pip install -I oslo.i18n==1.7 && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete"

RUN apt-get update && \
    apt-get -y install --no-install-recommends apache2 libapache2-mod-wsgi ssl-cert && \
    apt-get clean && \
    find /var/lib/apt/lists -type f -delete

RUN a2enmod wsgi ssl
ADD idm.conf /etc/apache2/sites-available/idm.conf
RUN a2dissite 000-default && a2ensite idm
RUN chown www-data:www-data ${KEYROCK_HOME}/horizon/openstack_dashboard/local
RUN mkdir -p ${KEYROCK_HOME}/horizon/static && chown www-data:www-data ${KEYROCK_HOME}/horizon/static

# Extract clientID and client-secret from database

COPY get-app-secrets.py /opt/fi-ware-idm/keystone/get-app-secrets.py
RUN bash -c "source /opt/fi-ware-idm/keystone/.venv/bin/activate && \
    mkdir /config && \
    python /opt/fi-ware-idm/keystone/get-app-secrets.py"

# Authzforce domain configuration

ADD config-domain.sh /opt/scripts/config-domain.sh
RUN chmod 755 /opt/scripts/config-domain.sh
ENTRYPOINT ["/opt/scripts/config-domain.sh"]
