#!/usr/bin/env bash

# VagrantFile Bootstrap v 0.4.1
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

# Project name
PROJECTNAME="${1}";

###################################
## Install
###################################

# Project folder
if [ ! -d "/var/www/html/htdocs" ]; then
    sudo mkdir "/var/www/html/htdocs";
fi

# Add repos
sudo add-apt-repository ppa:ondrej/php
sudo add-apt-repository ppa:chris-lea/redis-server

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# Tools
sudo apt-get install -y vim htop curl git sendmail

# Ruby
sudo apt-get install -y build-essential libsqlite3-dev ruby-dev
sudo gem install mailcatcher --no-rdoc --no-ri;

###################################
## PHP & Apache & MySQL
###################################

# MySQL pre-conf
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"

# Install
sudo apt-get install -y apache2
sudo apt-get install -y git-core redis-server
sudo apt-get install -y mysql-server
sudo apt-get install -y php7.0-common php7.0-dev php7.0-json php7.0-opcache php7.0-cli libapache2-mod-php7.0 php7.0 php7.0-mysql php7.0-fpm php7.0-curl php7.0-gd php7.0-mcrypt php7.0-mbstring php7.0-bcmath php7.0-zip php7.0-xml php-memcached

# Apache
sudo a2enmod rewrite

# PHP
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/apache2/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/apache2/php.ini
sudo phpenmod memcached

# MySQL : Create user / Create db / Import db
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -proot -e "CREATE DATABASE ${PROJECTNAME}";
if [ -f "/var/www/html/database.sql" ]; then
    mysql -uroot -proot ${PROJECTNAME} < /var/www/html/database.sql;
fi

# Mailcatcher
# - cron
sudo echo "@reboot $(which mailcatcher) --ip=0.0.0.0" >> tmp_crontab
crontab tmp_crontab
rm tmp_crontab
sudo update-rc.d cron defaults
# - enable
sudo phpenmod mailcatcher
echo "sendmail_path = /usr/bin/env $(which catchmail)" | sudo tee --append /etc/php/7.0/apache2/php.ini
# - start
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0

###################################
## Hosts
###################################

# Virtual host
VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${PROJECTNAME}.dev
    DocumentRoot "/var/www/html/htdocs"
    <Directory "/var/www/html/htdocs">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/000-default.conf

# Restart
service apache2 restart

###################################
## Add tools
###################################

# Magetools
cd /home/ubuntu && git clone https://github.com/Darklg/InteGentoMageTools.git;
touch /home/ubuntu/.bash_aliases;

# WP-Cli
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Aliases
echo "alias magetools='. /home/ubuntu/InteGentoMageTools/magetools.sh';" >> /home/ubuntu/.bash_aliases;
echo "alias ht='cd /var/www/html/htdocs/';" >> /home/ubuntu/.bash_aliases;
