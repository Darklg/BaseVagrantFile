# BaseVagrantFile

A Basic VagrantFile for LAMP Projects like WordPress & Magento

## Requirements :

Install Vagrant & Virtualbox.
Install Vagrant hostmanager `vagrant plugin install vagrant-hostmanager`.

## How to use :

- Create your project folder.
- Put the Vagrantfile in this folder.
- Change the IP address and the project name in the Vagrantfile (open with a text editor).
- Add a MySQL dump file if you need it at the root of the folder : database.sql.
- Clone your project in the htdocs folder : `git clone git@.../project.git htdocs`
- `vagrant up` at the root of the project folder.
- Your project is now available in your browser : http://mycoolproject.dev.

## What's installed :

- Apache.
- PHP 7.0.
- MySQL.
- Redis.
- Mailcatcher.
- git, curl.
