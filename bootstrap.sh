#!/usr/bin/env bash

# VagrantFile Bootstrap v 0.5.2
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

# External config
BVF_PROJECTNAME="${1}";
BVF_PROJECTNDD="${2}";

# Internal config
BVF_PHPINI_FILE="/etc/php/7.0/apache2/php.ini";
BVF_ROOT_DIR="/var/www/html";
BVF_HTDOCS_DIR="${BVF_ROOT_DIR}/htdocs";

###################################
## Install
###################################

# Project folder
if [ ! -d "${BVF_HTDOCS_DIR}" ]; then
    sudo mkdir "${BVF_HTDOCS_DIR}";
    echo "<?php phpinfo(); " > "${BVF_HTDOCS_DIR}/index.php";
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
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${BVF_PHPINI_FILE}
sed -i "s/display_errors = .*/display_errors = On/" ${BVF_PHPINI_FILE}
sudo phpenmod memcached

# MySQL
# - Create user / Create db / Import db / Config file
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;"
mysql -uroot -proot -e "CREATE DATABASE ${BVF_PROJECTNAME}";
if [ -f "${BVF_ROOT_DIR}/database.sql" ]; then
    mysql -uroot -proot ${BVF_PROJECTNAME} < "${BVF_ROOT_DIR}/database.sql";
fi
# - Config file
BVF_MYCNF=$(cat <<EOF
[mysql]
user=root
password=root
[mysqladmin]
user=root
password=root
EOF
)
echo "${BVF_MYCNF}" > /home/ubuntu/.my.cnf

# Mailcatcher
# - cron
sudo echo "@reboot $(which mailcatcher) --ip=0.0.0.0" >> tmp_crontab
crontab tmp_crontab
rm tmp_crontab
sudo update-rc.d cron defaults
# - enable
echo "sendmail_from = mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINI_FILE}
echo "sendmail_path = /usr/bin/env $(which catchmail) -f mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINI_FILE}
# - start
/usr/bin/env $(which mailcatcher) --ip=0.0.0.0

###################################
## Hosts
###################################

# Virtual host
BVF_VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${BVF_PROJECTNDD}
    DocumentRoot "${BVF_HTDOCS_DIR}"
    <Directory "${BVF_HTDOCS_DIR}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
)
echo "${BVF_VHOST}" > /etc/apache2/sites-available/000-default.conf

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

# Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Default folder
echo "cd ${BVF_HTDOCS_DIR} >& /dev/null" >> /home/ubuntu/.bash_aliases;

# Aliases
echo "alias magetools='. /home/ubuntu/InteGentoMageTools/magetools.sh';" >> /home/ubuntu/.bash_aliases;
echo "alias ht='cd ${BVF_HTDOCS_DIR}';" >> /home/ubuntu/.bash_aliases;
sudo chmod 0755 /home/ubuntu/.bash_aliases;

# Custom .inputrc
BVF_INPUTRC=$(cat <<EOF
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF
)
echo "${BVF_INPUTRC}" > /home/ubuntu/.inputrc;
