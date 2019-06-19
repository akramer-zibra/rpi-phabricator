FROM balenalib/rpi-raspbian:latest

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
  apt-get -y install supervisor git apache2 libapache2-mod-php5 mysql-server php5-mysql pwgen php-apc php5-mcrypt && \
  php5-mbstring php5-iconv php5-curl php5-gd && \
  echo "ServerName $HOST_NAME" >> /etc/apache2/apache2.conf

# Add image configuration and scripts
ADD start-apache2.sh /start-apache2.sh
ADD start-mysqld.sh /start-mysqld.sh
ADD run.sh /run.sh
RUN chmod 755 /*.sh
ADD my.cnf /etc/mysql/conf.d/my.cnf
ADD supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Add MySQL utils
ADD create_mysql_admin_user.sh /create_mysql_admin_user.sh
RUN chmod 755 /*.sh

# config to enable .htaccess
ADD apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Download phacilitator and dependencies
# https://secure.phabricator.com/book/phabricator/article/installation_guide/
RUN git clone https://github.com/phacility/libphutil.git
RUN git clone https://github.com/phacility/arcanist.git
RUN git clone https://github.com/phacility/phabricator.git

# Link phabricator webroot to apache's webroot folder
RUN mkdir -p ./phabricator && rm -fr /var/www/html && ln -s ./phabricator/webroot /var/www/html

# Configure Phabricator database
# https://secure.phabricator.com/book/phabricator/article/configuration_guide/
RUN ./phabricator/bin/storage upgrade --user root --password $MYSQL_PASS --force

#Enviornment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 32M
ENV PHP_POST_MAX_SIZE 32M

# Add volumes for MySQL 
VOLUME  ["/etc/mysql", "/var/lib/mysql" ]

EXPOSE 80 443
CMD ["/run.sh"]
