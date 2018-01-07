# BaseVagrantFile

A Basic VagrantFile for LAMP Projects like WordPress & Magento

## Requirements :

- Install Vagrant & Virtualbox.
- Install Vagrant hostmanager `vagrant plugin install vagrant-hostmanager`.

## How to use :

- Create your project folder.
- Put the Vagrantfile in this folder.
- Change the IP address and the project name in the Vagrantfile (open with a text editor).
- Add a MySQL dump file (with the .sql ext) if needed, at the root of the folder (only the first one will be used).
- Clone your project in the htdocs folder : `git clone git@.../project.git htdocs`
- `vagrant up` at the root of the project folder.
- Your project is now available in your browser : http://mycoolproject.test.

## What's installed :

- Apache.
- PHP 7.0.
- MySQL.
- Redis.
- Mailcatcher.
- git, curl.
