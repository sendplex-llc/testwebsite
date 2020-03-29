FROM centos:7
LABEL MAINTAINER Carlos Sura <carlos@sendplex.com>
LABEL Description="LAMP PHP 7.2. CentOS 7" \
	Usage="Kubernetes only" \
	Version="1.0"


# Install epel
RUN yum -y install epel-release

# Install RPMss
RUN rpm -Uvh http://rpms.remirepo.net/enterprise/remi-release-7.rpm


# Install Web Server
RUN yum -y update && yum clean all
RUN yum -y install httpd httpd-devel mod_ssl && yum clean all

# Install development tools and needed tools
RUN yum -y install \
gcc \
make \
openssl-devel \
python34 \
python34-devel \
python34-setuptools \
python-pip \
python-setuptools \
nano \
wget \
vim\
vim-enhanced \
bash-completion \
yum-utils \
git \
cronie

RUN yum groupinstall -y base && yum groupinstall -y 'Development Tools'
RUN yum clean all

# Networking
RUN echo "NETWORKING=yes" > /etc/sysconfig/network

# Using php7.2a
RUN yum-config-manager --enable remi-php72

# Install php
RUN yum install -y \
	php \
	php-devel \
	php-pear \
	php-common \
	php-dba \
	php-gd \
	php-intl \
	php-ldap \
	php-mbstring \
	php-mysqlnd \
	php-odbc \
	php-pdo \
	php-pecl-memcache \
	php-pgsql \
	php-pspell \
	php-recode \
	php-snmp \
	php-soap \
	php-xml \
	php-xmlrpc

# Install mongodb and adding it to php.ini
RUN sh -c 'printf "\n" | pecl install mongodb'
RUN sh -c 'echo short_open_tag=On >> /etc/php.ini'
RUN sh -c 'echo extension=mongodb.so >> /etc/php.ini'

# Installing Ioncube Loader
RUN cd /tmp \
	&& curl -o ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar -xvvzf ioncube.tar.gz \
    && mkdir -p /usr/local/ioncube \
    && mv ioncube/* /usr/local/ioncube \
    && rm -Rf ioncube.tar.gz ioncube

# Adding the ioncube extension to the php.ini
RUN sh -c 'echo zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.2.so >> /etc/php.ini'


# Custom environment variables defined here
ENV ALLOW_OVERRIDE All
ENV DATE_TIMEZONE America/New_York

# Install pip
RUN easy_install pip
RUN pip install --upgrade pip
RUN pip install supervisor

# Install sshd
RUN yum install -y openssh-server openssh-clients passwd
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && echo 'root:L@ck3d123' | chpasswd

# Adding files to the webservera
COPY /files/ /var/www/html/

RUN chmod 777 /var/www/html/*.php

# Adding custom supervisord configuration.
ADD supervisord.conf /etc/

# Creating directory for the certs
RUN mkdir -p /etc/httpd/ssl/

# Adding certificates
#ADD /certs/ /etc/httpd/ssl/

# Adding custom configuration for the vhost.
#ADD /vhosts/domain-name.conf /etc/httpd/conf.d/

# Adding cron job
#COPY /custom/crontab /etc/cron.d/crontab
#RUN chmod 0644 /etc/cron.d/crontab
#RUN chmod +x /etc/cron.d/crontab
#RUN crontab /etc/cron.d/crontab

# Create the log file to be able to run tail
#RUN touch /var/log/cron.log



# Exposed ports: ssh, http, https
EXPOSE 22 80 443

# Running supervisord
CMD ["supervisord", "-n"]
