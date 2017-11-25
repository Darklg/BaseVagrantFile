# BaseVagrantFile

A Basic VagrantFile for LAMP Projects like WordPress & Magento

## Requirements :

- Vagrant is installed on your machine.

## How to use :

- Create your project folder.
- Put the Vagrantfile in this folder.
- Change the IP address and the project name in the Vagrantfile (open with a texte editor).
- Add a MySQL dump file if you need it at the root of the folder : database.sql.
- Clone your project in the htdocs folder : `git clone git@.../project.git htdocs`
- `vagrant up` at the root of the project folder.

