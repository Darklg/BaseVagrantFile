#!/usr/bin/env bash

# VagrantFile Bootstrap v 0.10.1
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

# External config
BVF_PROJECTNAME="${1}";
if [ -z "${BVF_PROJECTNAME}" ]; then
    BVF_PROJECTNAME="mycoolproject";
fi
BVF_PROJECTNDD="${2}";
if [ -z "${BVF_PROJECTNDD}" ]; then
    BVF_PROJECTNDD="${BVF_PROJECTNAME}.test";
fi
BVF_PROJECTHASWORDPRESS="${3}";
BVF_PROJECTHASMAGENTO="${4}";
BVF_PROJECTPHPVERSION="${5}";
if [ -z "${BVF_PROJECTPHPVERSION}" ]; then
    BVF_PROJECTPHPVERSION="7.0";
fi
BVF_PROJECTSERVERTYPE="${6}";
if [ -z "${BVF_PROJECTSERVERTYPE}" ]; then
    BVF_PROJECTSERVERTYPE="apache";
fi

# Internal config
BVF_ROOT_DIR="/var/www/html";
BVF_HTDOCS_DIR="${BVF_ROOT_DIR}/htdocs";
BVF_LOGS_DIR="${BVF_ROOT_DIR}/logs";
BVF_CONTROL_FILE="/var/www/.basevagrantfile";
BVF_ALIASES_FILE="/home/ubuntu/.bash_aliases";

BVF_PHPINI_FILE="/etc/php/${BVF_PROJECTPHPVERSION}/apache2/php.ini";
if [[ ${BVF_PROJECTSERVERTYPE} == 'nginx' ]]; then
    BVF_PHPINI_FILE="/etc/php/${BVF_PROJECTPHPVERSION}/fpm/php.ini";
fi;

###################################
## Install
###################################

# Add repos
sudo add-apt-repository ppa:ondrej/php
sudo add-apt-repository ppa:chris-lea/redis-server

# Locales
sudo export DEBIAN_FRONTEND=noninteractive;
sudo locale-gen en_US en_US.UTF-8 fr_FR fr_FR.UTF-8
sudo dpkg-reconfigure locales
sudo export DEBIAN_FRONTEND=dialog;
sudo timedatectl set-timezone Europe/Paris;

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# Tools
sudo apt-get install -y vim htop curl git sendmail git-core

# Ruby
sudo apt-get install -y build-essential libsqlite3-dev ruby-dev
sudo gem install mailcatcher --no-rdoc --no-ri;

###################################
## PHP & Apache/nginx & MySQL
###################################

# Logs
if [ ! -d "${BVF_LOGS_DIR}" ]; then
    sudo mkdir "${BVF_LOGS_DIR}";
    chmod 0777 "${BVF_LOGS_DIR}";
fi

# MySQL pre-conf
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password root"
    sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password root"
fi;

# Install
sudo apt-get install -y mysql-server
if [[ ${BVF_PROJECTSERVERTYPE} == 'apache' ]]; then
    sudo apt-get install -y apache2
    sudo apt-get install -y libapache2-mod-php${BVF_PROJECTPHPVERSION}
else
    sudo apt-get install -y nginx
    sudo apt-get install -y php${BVF_PROJECTPHPVERSION}-fpm
fi;
sudo apt-get install -y php${BVF_PROJECTPHPVERSION}-common php${BVF_PROJECTPHPVERSION}-dev php${BVF_PROJECTPHPVERSION}-json php${BVF_PROJECTPHPVERSION}-opcache php${BVF_PROJECTPHPVERSION}-cli php${BVF_PROJECTPHPVERSION} php${BVF_PROJECTPHPVERSION}-mysql php${BVF_PROJECTPHPVERSION}-fpm php${BVF_PROJECTPHPVERSION}-curl php${BVF_PROJECTPHPVERSION}-gd php${BVF_PROJECTPHPVERSION}-mcrypt php${BVF_PROJECTPHPVERSION}-mbstring php${BVF_PROJECTPHPVERSION}-bcmath php${BVF_PROJECTPHPVERSION}-zip php${BVF_PROJECTPHPVERSION}-xml
sudo apt-get install -y php-memcached
sudo apt-get install -y redis-server php${BVF_PROJECTPHPVERSION}-redis

# Apache
if [[ ${BVF_PROJECTSERVERTYPE} == 'apache' ]]; then
    sudo a2enmod rewrite ext_filter headers
fi;

# PHP
BVF_PHPERROR_LOG=$(sed 's/\//\\\//g' <<< "${BVF_LOGS_DIR}/php-error.log");
sed -i "s/;error_log = .*/error_log = ${BVF_PHPERROR_LOG}/" ${BVF_PHPINI_FILE}
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${BVF_PHPINI_FILE}
sed -i "s/display_errors = .*/display_errors = On/" ${BVF_PHPINI_FILE}
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 32M/" ${BVF_PHPINI_FILE}
sudo phpenmod memcached

# MySQL
# - Create user
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;";
mysql -uroot -proot -e "SET GLOBAL show_compatibility_56 = ON;";
# - Create db
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${BVF_PROJECTNAME}";
# - Import first .sql file available
for dbfile in `ls ${BVF_ROOT_DIR}/*.sql 2>/dev/null`; do
    if [[ -f "${dbfile}" ]]; then
        mysql -uroot -proot ${BVF_PROJECTNAME} < "${dbfile}";
        break;
    fi;
done;

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
if [ ! -f "/home/ubuntu/.my.cnf" ]; then
    echo "${BVF_MYCNF}" > /home/ubuntu/.my.cnf
fi;

# Mailcatcher
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    # - cron
    echo "@reboot $(which mailcatcher) --ip=0.0.0.0" | sudo tee --append tmp_crontab
    crontab tmp_crontab
    sudo rm tmp_crontab
    sudo update-rc.d cron defaults
    # - enable
    echo "sendmail_from = mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINI_FILE}
    echo "sendmail_path = /usr/bin/env $(which catchmail) -f mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINI_FILE}
    # - start
    /usr/bin/env $(which mailcatcher) --ip=0.0.0.0
fi;

# Project folder
if [ ! -d "${BVF_HTDOCS_DIR}" ]; then
    sudo mkdir "${BVF_HTDOCS_DIR}";
    echo "<?php phpinfo(); " > "${BVF_HTDOCS_DIR}/index.php";
fi

# PHPMyAdmin
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/dbconfig-install boolean true';
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/app-password-confirm password root';
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/admin-pass password root';
    sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/mysql/app-pass password root';
    if [[ ${BVF_PROJECTSERVERTYPE} == 'nginx' ]]; then
        sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect nginx';
    else
        sudo debconf-set-selections <<< 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2';
    fi;
    sudo apt-get install -y phpmyadmin;
fi;

###################################
## Hosts
###################################

# Logs
BVF_SERVER_ACCESSLOG="${BVF_LOGS_DIR}/${BVF_PROJECTNDD}-access.log";
BVF_SERVER_ERRORLOG="${BVF_LOGS_DIR}/${BVF_PROJECTNDD}-error.log";

touch ${BVF_SERVER_ACCESSLOG};
touch ${BVF_SERVER_ERRORLOG};

chmod 0777 ${BVF_SERVER_ACCESSLOG};
chmod 0777 ${BVF_SERVER_ERRORLOG};


if [[ ${BVF_PROJECTSERVERTYPE} == 'nginx' ]]; then
    # Virtual host
    BVF_VHOST=$(cat <<EOF
server {
    listen 80;
    server_name ${BVF_PROJECTNDD};

    root ${BVF_HTDOCS_DIR};

    index index.php index.html;

    access_log ${BVF_SERVER_ACCESSLOG};
    error_log ${BVF_SERVER_ERRORLOG};

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_index index.php;
        fastcgi_pass unix:/run/php/php${BVF_PROJECTPHPVERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    location /phpmyadmin {
        root /usr/share/;
        index index.php;
        try_files \$uri \$uri/ =404;

        location ~ ^/phpmyadmin/(doc|sql|setup)/ {
            deny all;
        }

        location ~ /phpmyadmin/(.+\.php)\$ {
            fastcgi_pass unix:/run/php/php${BVF_PROJECTPHPVERSION}-fpm.sock;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            include fastcgi_params;
            include snippets/fastcgi-php.conf;
        }
    }
}
EOF
);
    echo "${BVF_VHOST}" > /etc/nginx/sites-available/default

    # Restart
    sudo service nginx restart
fi;

if [[ ${BVF_PROJECTSERVERTYPE} == 'apache' ]]; then

    # Virtual host
    BVF_VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${BVF_PROJECTNDD}
    DocumentRoot "${BVF_HTDOCS_DIR}"
    CustomLog ${BVF_SERVER_ACCESSLOG} combined
    ErrorLog ${BVF_SERVER_ERRORLOG}
    <Directory "${BVF_HTDOCS_DIR}">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
);
    echo "${BVF_VHOST}" > /etc/apache2/sites-available/000-default.conf

    # Restart
    sudo service apache2 restart
fi;

###################################
## Add tools
###################################

# Composer
curl -s https://getcomposer.org/installer | php
if [ ! -f "/usr/local/bin/composer" ]; then
    mv composer.phar /usr/local/bin/composer
else
    composer self-update;
fi;

# Aliases
if [ ! -f "${BVF_ALIASES_FILE}" ]; then
    touch "${BVF_ALIASES_FILE}";
fi;

# Inte Starter
cd /home/ubuntu && git clone https://github.com/Darklg/InteStarter.git;
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    echo "alias newinte='. /home/ubuntu/InteStarter/newinte.sh';" >> "${BVF_ALIASES_FILE}";
fi;

if [[ ${BVF_PROJECTHASMAGENTO} == '1' ]]; then
    # Magetools
    cd /home/ubuntu && git clone https://github.com/Darklg/InteGentoMageTools.git;
    if [ ! -f "${BVF_CONTROL_FILE}" ]; then
        echo "alias magetools='. /home/ubuntu/InteGentoMageTools/magetools.sh';" >> "${BVF_ALIASES_FILE}";
    fi;
fi;

if [[ ${BVF_PROJECTHASWORDPRESS} == '1' ]]; then
    # WP-Cli
    cd /home/ubuntu && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    chmod +x wp-cli.phar
    if [ ! -f "/usr/local/bin/wp" ]; then
        sudo mv wp-cli.phar /usr/local/bin/wp
    fi;
    # WPU Installer
    cd /home/ubuntu && git clone https://github.com/WordPressUtilities/WPUInstaller.git;
    if [ ! -f "${BVF_CONTROL_FILE}" ]; then
        echo "alias wpuinstaller='. /home/ubuntu/WPUInstaller/start.sh';" >> "${BVF_ALIASES_FILE}";
    fi;
fi;

# Default folder
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    echo "cd ${BVF_HTDOCS_DIR} >& /dev/null" >> "${BVF_ALIASES_FILE}";
fi;

# Aliases
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    echo "alias ht='cd ${BVF_HTDOCS_DIR}';" >> "${BVF_ALIASES_FILE}";
fi;
sudo chmod 0755 "${BVF_ALIASES_FILE}";

# Custom .inputrc
BVF_INPUTRC=$(cat <<EOF
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF
)
if [ ! -f "/home/ubuntu/.inputrc" ]; then
    echo "${BVF_INPUTRC}" > /home/ubuntu/.inputrc;
fi;

echo '###################################';
echo '## VAGRANT BOX IS INSTALLED';
echo '###################################';

touch "${BVF_CONTROL_FILE}";
