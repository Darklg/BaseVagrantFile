#!/usr/bin/env bash

# VagrantFile Bootstrap v 0.18.1
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

echo '###################################';
echo '## INSTALLING VagrantFile v 0.18.1';
echo '###################################';

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
BVF_PROJECTUSEHTTPS="${7}";
if [ -z "${BVF_PROJECTUSEHTTPS}" ]; then
    BVF_PROJECTUSEHTTPS="0";
fi
BVF_PROJECTALIASES="${8}";
if [ -z "${BVF_PROJECTALIASES}" ]; then
    BVF_PROJECTALIASES="";
fi
BVF_PROJECTREPO="${9}";
if [ -z "${BVF_PROJECTREPO}" ]; then
    BVF_PROJECTREPO="";
fi

# Internal config
BVF_ROOT_DIR="/var/www/html";
BVF_TOOLS_DIR="/home/vagrant";
BVF_HTDOCS_DIR="${BVF_ROOT_DIR}/htdocs";
BVF_LOGS_DIR="${BVF_ROOT_DIR}/logs";
BVF_CONTROL_FILE="/var/www/.basevagrantfile";
BVF_ALIASES_FILE="${BVF_TOOLS_DIR}/.bash_aliases";
BVF_PROFILE_FILE="${BVF_TOOLS_DIR}/.bash_profile";
BVF_INPUTRC_FILE="${BVF_TOOLS_DIR}/.inputrc";
BVF_UPLOADMAX="32M";

BVF_HTDOCS_FILES=(wp-config.php app/etc/local.xml app/etc/env.php auth.json);

BVF_PHPINI_FILE="/etc/php/${BVF_PROJECTPHPVERSION}/apache2/php.ini";
BVF_PHPINICLI_FILE="/etc/php/${BVF_PROJECTPHPVERSION}/cli/php.ini";
if [[ "${BVF_PROJECTSERVERTYPE}" == 'nginx' ]]; then
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
sudo apt-get install -y \
    vim \
    htop \
    curl \
    sendmail \
    git \
    git-core;

# Node
sudo apt-get install -y \
    nodejs \
    npm;

# Ruby
sudo apt-get install -y \
    build-essential \
    libsqlite3-dev \
    ruby-dev;
sudo gem install mailcatcher --no-rdoc --no-ri;

# SSL certif
if [[ ${BVF_PROJECTUSEHTTPS} == '1' ]]; then
    cd "${BVF_ROOT_DIR}";
    openssl genrsa -out "${BVF_PROJECTNDD}".key 2048;
    openssl req -new -x509 -key "${BVF_PROJECTNDD}".key -out "${BVF_PROJECTNDD}".cert -days 3650 -subj /CN="${BVF_PROJECTNDD}";
fi;

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
    sudo apt-get install -y \
        apache2 \
        libapache2-mod-php${BVF_PROJECTPHPVERSION};
else
    sudo apt-get install -y \
        nginx \
        php${BVF_PROJECTPHPVERSION}-fpm;
fi;
sudo apt-get install -y \
    php${BVF_PROJECTPHPVERSION} \
    php${BVF_PROJECTPHPVERSION}-common \
    php${BVF_PROJECTPHPVERSION}-cli \
    php${BVF_PROJECTPHPVERSION}-dev \
    php${BVF_PROJECTPHPVERSION}-json \
    php${BVF_PROJECTPHPVERSION}-opcache \
    php${BVF_PROJECTPHPVERSION}-mysql \
    php${BVF_PROJECTPHPVERSION}-fpm \
    php${BVF_PROJECTPHPVERSION}-curl \
    php${BVF_PROJECTPHPVERSION}-gd \
    php${BVF_PROJECTPHPVERSION}-mbstring \
    php${BVF_PROJECTPHPVERSION}-bcmath \
    php${BVF_PROJECTPHPVERSION}-zip \
    php${BVF_PROJECTPHPVERSION}-soap \
    php${BVF_PROJECTPHPVERSION}-xml \
    php${BVF_PROJECTPHPVERSION}-intl \
    php-memcached \
    redis-server \
    php-redis;

# Special extensions
sudo apt-get install -y \
    php-mcrypt \
    php-imagick;

# Autostart redis
sudo systemctl enable redis-server;

# Apache
if [[ ${BVF_PROJECTSERVERTYPE} == 'apache' ]]; then
    sudo a2enmod rewrite ext_filter headers
fi;

# PHP
BVF_PHPERROR_LOG=$(sed 's/\//\\\//g' <<< "${BVF_LOGS_DIR}/php-error.log");
sed -i "s/;error_log = .*/error_log = ${BVF_PHPERROR_LOG}/" ${BVF_PHPINI_FILE}
sed -i "s/;error_log = .*/error_log = ${BVF_PHPERROR_LOG}/" ${BVF_PHPINICLI_FILE}
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${BVF_PHPINI_FILE}
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" ${BVF_PHPINICLI_FILE}
sed -i "s/display_errors = .*/display_errors = On/" ${BVF_PHPINI_FILE}
sed -i "s/display_errors = .*/display_errors = On/" ${BVF_PHPINICLI_FILE}
sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${BVF_UPLOADMAX}/" ${BVF_PHPINI_FILE}
sed -i "s/upload_max_filesize = .*/upload_max_filesize = ${BVF_UPLOADMAX}/" ${BVF_PHPINICLI_FILE}
sed -i "s/post_max_size = .*/post_max_size = ${BVF_UPLOADMAX}/" ${BVF_PHPINI_FILE}
sed -i "s/post_max_size = .*/post_max_size = ${BVF_UPLOADMAX}/" ${BVF_PHPINICLI_FILE}
sudo phpenmod memcached

# MySQL
# - Create user
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION; FLUSH PRIVILEGES;";
mysql -uroot -proot -e "SET GLOBAL show_compatibility_56 = ON;";
# - Create db
mysql -uroot -proot -e "CREATE DATABASE IF NOT EXISTS ${BVF_PROJECTNAME}";

# - Import first .sql file available
for dbfile in `ls ${BVF_ROOT_DIR}/*.sql ${BVF_ROOT_DIR}/*.sql.gz ${BVF_ROOT_DIR}/*.sql.bz2 2>/dev/null`; do
    if [[ -f "${dbfile}" ]]; then
        if [[ "${dbfile}" == *bz2 ]]; then
            bzip2 -dk "${dbfile}";
            dbfile="${dbfile/\.bz2/}";
        fi;
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
if [ ! -f "${BVF_TOOLS_DIR}/.my.cnf" ]; then
    echo "${BVF_MYCNF}" > "${BVF_TOOLS_DIR}/.my.cnf";
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
    echo "sendmail_from = mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINICLI_FILE}
    echo "sendmail_path = /usr/bin/env $(which catchmail) -f mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINI_FILE}
    echo "sendmail_path = /usr/bin/env $(which catchmail) -f mailcatcher@${BVF_PROJECTNDD}" | sudo tee --append ${BVF_PHPINICLI_FILE}
    # - start
    /usr/bin/env $(which mailcatcher) --ip=0.0.0.0
fi;

# Project folder
if [ ! -d "${BVF_HTDOCS_DIR}" ]; then
    sudo mkdir "${BVF_HTDOCS_DIR}";
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

BVF_NGINX_PHPMYADMIN=$(cat <<EOF
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
EOF
);


BVF_NGINX_SERVER=$(cat <<EOF
listen 80;
server_name ${BVF_PROJECTNDD} ${BVF_PROJECTALIASES};
access_log ${BVF_SERVER_ACCESSLOG};
error_log ${BVF_SERVER_ERRORLOG};
client_max_body_size ${BVF_UPLOADMAX};
EOF
);

if [[ ${BVF_PROJECTSERVERTYPE} == 'nginx' ]]; then
    # Virtual host
    BVF_VHOST=$(cat <<EOF
server {
    ${BVF_NGINX_SERVER}

    root ${BVF_HTDOCS_DIR};

    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_index index.php;
        fastcgi_pass unix:/run/php/php${BVF_PROJECTPHPVERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include /etc/nginx/fastcgi_params;
    }

    ${BVF_NGINX_PHPMYADMIN}

}
EOF
);

if [[ ${BVF_PROJECTHASMAGENTO} == '2' ]]; then
    BVF_VHOST=$(cat <<EOF
upstream fastcgi_backend {
    server unix:/var/run/php/php${BVF_PROJECTPHPVERSION}-fpm.sock;
}

server {
    ${BVF_NGINX_SERVER}

    set \$MAGE_ROOT ${BVF_HTDOCS_DIR};
    set \$MAGE_MODE developer;
    set \$MAGE_RUN_TYPE website;
    include ${BVF_HTDOCS_DIR}/nginx*.conf.sample;

    ${BVF_NGINX_PHPMYADMIN}

}
EOF
);
fi;

if [[ ${BVF_PROJECTUSEHTTPS} == '1' ]]; then
    BVF_VHOST=$(cat <<EOF
${BVF_VHOST}

server {
    listen 443 ssl;
    server_name ${BVF_PROJECTNDD};
    ssl_certificate ${BVF_ROOT_DIR}/${BVF_PROJECTNDD}.cert;
    ssl_certificate_key ${BVF_ROOT_DIR}/${BVF_PROJECTNDD}.key;
    ssl on;
    location / {
        proxy_pass         http://127.0.0.1/;
        proxy_redirect     off;
        access_log         off;
        proxy_pass_header  Set-Cookie;
        proxy_set_header   Host             \$host;
        proxy_set_header   X-Real-IP        \$remote_addr;
        proxy_set_header   X-Forwarded-For  \$proxy_add_x_forwarded_for;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404      1m;
    }
}
EOF
);
fi;

    echo "${BVF_VHOST}" > /etc/nginx/sites-available/default

    # Restart
    sudo service nginx restart
fi;

BVF_APACHE_ALIAS="";
if [ ! -z "${BVF_PROJECTALIASES}" ]; then
    BVF_APACHE_ALIAS="ServerAlias ${BVF_PROJECTALIASES}";
fi

BVF_APACHE_SERVER=$(cat <<EOF
ServerName ${BVF_PROJECTNDD}
${BVF_APACHE_ALIAS}
DocumentRoot "${BVF_HTDOCS_DIR}"
CustomLog ${BVF_SERVER_ACCESSLOG} combined
ErrorLog ${BVF_SERVER_ERRORLOG}
<Directory "${BVF_HTDOCS_DIR}">
    AllowOverride All
    Require all granted
</Directory>
EOF
);

if [[ ${BVF_PROJECTSERVERTYPE} == 'apache' ]]; then

    # Virtual host
    BVF_VHOST=$(cat <<EOF
<VirtualHost *:80>
    ${BVF_APACHE_SERVER}
</VirtualHost>
EOF
);


if [[ ${BVF_PROJECTUSEHTTPS} == '1' ]]; then
    # Virtual host
    BVF_VHOST=$(cat <<EOF
<VirtualHost *:443>
    ${BVF_APACHE_SERVER}
    #adding custom SSL cert
    SSLEngine on
    SSLCertificateFile ${BVF_ROOT_DIR}/${BVF_PROJECTNDD}.cert
    SSLCertificateKeyFile ${BVF_ROOT_DIR}/${BVF_PROJECTNDD}.key
</VirtualHost>
<VirtualHost *:80>
    ${BVF_APACHE_SERVER}
    Redirect permanent / https://${BVF_PROJECTNDD}/
</VirtualHost>
EOF
);
fi;


    echo "${BVF_VHOST}" > /etc/apache2/sites-available/000-default.conf

    # Restart
    sudo service apache2 restart
fi;

###################################
## Add tools
###################################

# Aliases
if [ ! -f "${BVF_ALIASES_FILE}" ]; then
    touch "${BVF_ALIASES_FILE}";
fi;

# Global composer
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    cd "${BVF_TOOLS_DIR}";
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    echo "alias composer='php ${BVF_TOOLS_DIR}/composer.phar';" >> "${BVF_ALIASES_FILE}";
fi;

# Profile
if [ ! -f "${BVF_PROFILE_FILE}" ]; then
    touch "${BVF_PROFILE_FILE}";
    # Init file
    BVF_PROFILE_FILE__CONTENT=$(cat <<EOF
#!/bin/bash
if [ -f ~/.bashrc ]; then
   source ~/.bashrc
fi
cd ${BVF_HTDOCS_DIR} >& /dev/null;
EOF
);
echo "${BVF_PROFILE_FILE__CONTENT}" >> "${BVF_PROFILE_FILE}";
fi;

# Inte Starter
cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/Darklg/InteStarter.git;
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    echo "alias newinte='. ${BVF_TOOLS_DIR}/InteStarter/newinte.sh';" >> "${BVF_ALIASES_FILE}";
fi;


if [[ ${BVF_PROJECTHASMAGENTO} == '1' ]] || [[ ${BVF_PROJECTHASMAGENTO} == '2' ]]; then


    if [[ ${BVF_PROJECTHASMAGENTO} == '1' ]]; then
        # Magerun
        wget https://files.magerun.net/n98-magerun.phar
        sudo chmod +x n98-magerun.phar
        sudo cp n98-magerun.phar /usr/local/bin/
        if [ ! -f "${BVF_CONTROL_FILE}" ]; then
            echo "alias magerun='php /usr/local/bin/n98-magerun.phar';" >> "${BVF_ALIASES_FILE}";
        fi;

        # Magetools
        cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/Darklg/InteGentoMageTools.git;
        if [ ! -f "${BVF_CONTROL_FILE}" ]; then
            echo "alias magetools='. ${BVF_TOOLS_DIR}/InteGentoMageTools/magetools.sh';" >> "${BVF_ALIASES_FILE}";
        fi;
    fi;

    if [[ ${BVF_PROJECTHASMAGENTO} == '2' ]]; then
        # Magerun
        wget https://files.magerun.net/n98-magerun2.phar
        sudo chmod +x n98-magerun2.phar
        sudo cp n98-magerun2.phar /usr/local/bin/
        if [ ! -f "${BVF_CONTROL_FILE}" ]; then
            echo "alias magerun='php /usr/local/bin/n98-magerun2.phar';" >> "${BVF_ALIASES_FILE}";
        fi;

        # Magetools
        cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/integento/InteGentoMageTools2.git;
        if [ ! -f "${BVF_CONTROL_FILE}" ]; then
            echo "alias magetools='. ${BVF_TOOLS_DIR}/InteGentoMageTools2/magetools.sh';" >> "${BVF_ALIASES_FILE}";
        fi;
    fi;

fi;

if [[ ${BVF_PROJECTHASWORDPRESS} == '1' ]]; then
    # WP-Cli
    cd "${BVF_TOOLS_DIR}" && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar;
    chmod +x wp-cli.phar
    if [ ! -f "/usr/local/bin/wp" ]; then
        sudo mv wp-cli.phar /usr/local/bin/wp
    fi;

    # WPU Installer
    cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/WordPressUtilities/WPUInstaller.git;
    if [ ! -f "${BVF_CONTROL_FILE}" ]; then
        echo "alias wpuinstaller='. ${BVF_TOOLS_DIR}/WPUInstaller/start.sh';" >> "${BVF_ALIASES_FILE}";
    fi;

    # WPU Tools
    cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/WordPressUtilities/wputools.git;
    if [ ! -f "${BVF_CONTROL_FILE}" ]; then
        cd "${BVF_TOOLS_DIR}/wputools/";
        git submodule update --init --recursive;
        echo "alias wputools='. ${BVF_TOOLS_DIR}/wputools/wputools.sh';" >> "${BVF_ALIASES_FILE}";
    fi;

    # WPU Entity Creator
    cd "${BVF_TOOLS_DIR}" && git clone --depth 1 https://github.com/WordPressUtilities/wpuentitycreator.git;
    if [ ! -f "${BVF_CONTROL_FILE}" ]; then
        echo "alias wpuentitycreator='. ${BVF_TOOLS_DIR}/wpuentitycreator/wpuentitycreator.sh';" >> "${BVF_ALIASES_FILE}";
    fi;

fi;

## Common aliases
if [ ! -f "${BVF_CONTROL_FILE}" ]; then
    # Aliases
    echo "alias ht='cd ${BVF_HTDOCS_DIR}';" >> "${BVF_ALIASES_FILE}";
    # Common aliases
    echo "alias ..='cd ..';" >> "${BVF_ALIASES_FILE}";
    echo "function mkdircd () { mkdir -p \"\$@\" && cd \"\$@\"; }" >> "${BVF_ALIASES_FILE}";

    # Custom prompt : PS1
    BVF_PS1=$(cat <<EOF
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
export PS1="\[\e[0;36m\]\u@\h: \[\e[m\]\[\e[0;31m\]\w\[\e[m\]\[\033[00m\]\$(parse_git_branch) \n$ "
EOF
);
echo "${BVF_PS1}" >> "${BVF_PROFILE_FILE}";


fi;

## Project folder init
if [ "${BVF_PROJECTREPO}test" == "test" ];then
    # Basic phpinfo
    BVF_INSTALLER='';
    if [ ! -f "${BVF_HTDOCS_DIR}/index.php" ]; then
        echo "<?php phpinfo(); " > "${BVF_HTDOCS_DIR}/index.php";
    fi;
else
    # Installer for project
    BVF_INSTALLER=$(cat <<EOF
#!/bin/bash
if [ ! -d "${BVF_HTDOCS_DIR}/.git" ]; then
    echo '## CLONE PROJECT';
    cd ${BVF_ROOT_DIR};
    rm -rf ${BVF_HTDOCS_DIR};
    git clone ${BVF_PROJECTREPO} ${BVF_HTDOCS_DIR};
    git config --global user.email "${BVF_PROJECTNAME}@${BVF_PROJECTNDD}";
    git config --global user.name "${BVF_PROJECTNAME}";
    cd ${BVF_HTDOCS_DIR};
    git submodule update --init --recursive;

    echo '## RESTORE CONFIG FILES';
    BVF_HTDOCS_FILES=(${BVF_HTDOCS_FILES[*]});
    for BVF_BACKUP_FILE in \${BVF_HTDOCS_FILES[*]}; do
        BVF_BACKUP_FILENAME=\$(basename \${BVF_BACKUP_FILE});
        if [ -f "${BVF_ROOT_DIR}/\${BVF_BACKUP_FILENAME}" ] && [ ! -f "${BVF_HTDOCS_DIR}/\${BVF_BACKUP_FILE}" ]; then
            cp "${BVF_ROOT_DIR}/\${BVF_BACKUP_FILENAME}" "${BVF_HTDOCS_DIR}/\${BVF_BACKUP_FILE}";
        fi;
    done;

    echo '## COMPOSER INSTALL';
    cd ${BVF_HTDOCS_DIR};
    if [ -f "${BVF_HTDOCS_DIR}/composer.json" ]; then
        composer install;
    fi;
fi;
EOF
);
    if [ ! -f "${BVF_TOOLS_DIR}/installer.sh" ]; then
        echo "${BVF_INSTALLER}" >> "${BVF_TOOLS_DIR}/installer.sh";
        echo "/bin/bash ${BVF_TOOLS_DIR}/installer.sh" >> "${BVF_PROFILE_FILE}";
    fi;
fi;

## Backup file
if [ ! -f "${BVF_TOOLS_DIR}/backup.sh" ]; then
    BVF_BACKUP=$(cat <<EOF
#!/bin/bash

echo "# DUMP DATABASE";
mysqldump -u root -proot ${BVF_PROJECTNAME} > ${BVF_ROOT_DIR}/backup.sql;
gzip -v  ${BVF_ROOT_DIR}/backup.sql ;

echo "# DUMP CONFIG FILES";
BVF_HTDOCS_FILES=(${BVF_HTDOCS_FILES[*]});
for BVF_BACKUP_FILE in \${BVF_HTDOCS_FILES[*]}; do
    if [ -f "${BVF_HTDOCS_DIR}/\${BVF_BACKUP_FILE}" ]; then
        BVF_BACKUP_FILENAME=\$(basename \${BVF_BACKUP_FILE});
        cp "${BVF_HTDOCS_DIR}/\${BVF_BACKUP_FILE}" "${BVF_ROOT_DIR}/\${BVF_BACKUP_FILENAME}";
    fi;
done;

EOF
);
    echo "${BVF_BACKUP}" >> "${BVF_TOOLS_DIR}/backup.sh";
    echo "alias backupnow='/bin/bash ${BVF_TOOLS_DIR}/backup.sh';" >> "${BVF_ALIASES_FILE}";
fi;

sudo chmod 0755 "${BVF_ALIASES_FILE}";
sudo chmod 0755 "${BVF_PROFILE_FILE}";

BVF_SWAP=$(cat <<EOF
#!/bin/bash
if [ ! -f /swapfile ]; then
    echo "## CREATE SWAP";
    sudo fallocate -l 1G /swapfile;
    sudo chmod 600 /swapfile;
    sudo mkswap /swapfile;
    sudo swapon /swapfile;
fi;
EOF
);
echo "${BVF_SWAP}" >> "${BVF_TOOLS_DIR}/swap.sh";

if [[ ${BVF_PROJECTHASMAGENTO} == '2' ]]; then
    echo "/bin/bash ${BVF_TOOLS_DIR}/swap.sh" >> "${BVF_PROFILE_FILE}";
fi;

# Custom .inputrc
BVF_INPUTRC=$(cat <<EOF
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF
)
if [ ! -f "${BVF_INPUTRC_FILE}" ]; then
    echo "${BVF_INPUTRC}" > "${BVF_INPUTRC_FILE}";
fi;

echo '###################################';
echo '## VAGRANT BOX IS INSTALLED';
if [ -n "${BVF_INSTALLER}" ];then
    echo '## INSTALL PROJECT :';
    echo '## - ssh-add -k';
    echo '## - vagrant ssh';
fi;
echo '###################################';

touch "${BVF_CONTROL_FILE}";
