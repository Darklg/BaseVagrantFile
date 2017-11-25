# -*- mode: ruby -*-
# vi: set ft=ruby :

# Project settings
VAGRANTFILE_MYPROJECT_IP = "192.168.33.1"
VAGRANTFILE_MYPROJECT_NAME = "mycoolproject"

# Vagrantfile API/syntax version
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/trusty64"

  # Create a private network, which allows host-only access to the machine using a specific IP.
  config.vm.network "private_network", ip: VAGRANTFILE_MYPROJECT_IP

  # Share an additional folder to the guest VM. The first argument is the path on the host to the actual folder.
  # The second argument is the path on the guest to mount the folder.
  config.vm.synced_folder "./", "/var/www/html", :mount_options => ["dmode=777,fmode=666"]

  # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
  config.vm.provision :shell, path: "bootstrap.sh", :args => [VAGRANTFILE_MYPROJECT_NAME]

end
