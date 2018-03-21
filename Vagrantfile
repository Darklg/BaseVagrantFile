# -*- mode: ruby -*-
# vi: set ft=ruby :

# VagrantFile Bootstrap v 0.10.0
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

# Project settings
VAGRANTFILE_MYPROJECT_IP = "192.168.33.99"
VAGRANTFILE_MYPROJECT_NAME = "mycoolproject"
VAGRANTFILE_MYPROJECT_DOMAIN = "mycoolproject.test"
VAGRANTFILE_MYPROJECT_HAS_WORDPRESS = "1"
VAGRANTFILE_MYPROJECT_HAS_MAGENTO = "1"
VAGRANTFILE_MYPROJECT_PHP_VERSION = "7.0"
VAGRANTFILE_MYPROJECT_SERVER_TYPE = "apache"

# Vagrantfile API/syntax version.
VAGRANTFILE_API_VERSION = "2"

# Load args
VAGRANTFILE_ARGS = [
  VAGRANTFILE_MYPROJECT_NAME,
  VAGRANTFILE_MYPROJECT_DOMAIN,
  VAGRANTFILE_MYPROJECT_HAS_WORDPRESS,
  VAGRANTFILE_MYPROJECT_HAS_MAGENTO,
  VAGRANTFILE_MYPROJECT_PHP_VERSION,
  VAGRANTFILE_MYPROJECT_SERVER_TYPE
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/xenial64"

  # Create a private network, which allows host-only access to the machine using a specific IP.
  config.vm.network "private_network", ip: VAGRANTFILE_MYPROJECT_IP

  # Share an additional folder to the guest VM. The first argument is the path on the host to the actual folder.
  # The second argument is the path on the guest to mount the folder.
  config.vm.synced_folder "./", "/var/www/html", :mount_options => ["dmode=777,fmode=666"]

  # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
  config.vm.provision :shell, path: "https://raw.githubusercontent.com/Darklg/BaseVagrantFile/master/bootstrap.sh", :args => VAGRANTFILE_ARGS
  # OR Local version for debug purposes
  # config.vm.provision :shell, path: "bootstrap.sh", :args => VAGRANTFILE_ARGS

  # Restart some services after mounting
  config.vm.provision :shell, :inline => "sudo systemctl restart apache2", run: "always"

  # Hostname
  config.vm.hostname = VAGRANTFILE_MYPROJECT_DOMAIN
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true

end
