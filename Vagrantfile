# -*- mode: ruby -*-
# vi: set ft=ruby :

# VagrantFile Bootstrap v 0.17.0
#
# @author      Darklg <darklg.blog@gmail.com>
# @copyright   Copyright (c) 2017 Darklg
# @license     MIT

# Project settings
VAGRANTFILE_MYPROJECT_IP = "192.168.33.99"
VAGRANTFILE_MYPROJECT_NAME = "mycoolproject"
VAGRANTFILE_MYPROJECT_DOMAIN = "mycoolproject.test"
VAGRANTFILE_MYPROJECT_DOMAINALIASES = ""
VAGRANTFILE_MYPROJECT_HAS_WORDPRESS = "0"
VAGRANTFILE_MYPROJECT_HAS_MAGENTO = "0"
VAGRANTFILE_MYPROJECT_PHP_VERSION = "7.0"
VAGRANTFILE_MYPROJECT_SERVER_TYPE = "apache"
VAGRANTFILE_MYPROJECT_HTTPS = "0"
VAGRANTFILE_MYPROJECT_REPO = ""

# Vagrantfile API/syntax version.
VAGRANTFILE_API_VERSION = "2"

# Load args
VAGRANTFILE_ARGS = [
  VAGRANTFILE_MYPROJECT_NAME,
  VAGRANTFILE_MYPROJECT_DOMAIN,
  VAGRANTFILE_MYPROJECT_HAS_WORDPRESS,
  VAGRANTFILE_MYPROJECT_HAS_MAGENTO,
  VAGRANTFILE_MYPROJECT_PHP_VERSION,
  VAGRANTFILE_MYPROJECT_SERVER_TYPE,
  VAGRANTFILE_MYPROJECT_HTTPS,
  VAGRANTFILE_MYPROJECT_DOMAINALIASES,
  VAGRANTFILE_MYPROJECT_REPO
]

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  required_plugins = %w( vagrant-hostmanager vagrant-disksize )
  _retry = false
  required_plugins.each do |plugin|
    unless Vagrant.has_plugin? plugin
      system "vagrant plugin install #{plugin}"
      _retry=true
    end
  end

  if (_retry)
    exec "vagrant " + ARGV.join(' ')
  end

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "ubuntu/xenial64"

  # Box modifications
  config.vm.provider "virtualbox" do |vb|
     vb.name = VAGRANTFILE_MYPROJECT_NAME
     vb.memory = 1024
     # Sync vagrant time : Thanks to https://bit.ly/2A9APEH
     vb.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 10000 ]
  end

  # Disk Size
  config.disksize.size = '15GB'

  # Create a private network, which allows host-only access to the machine using a specific IP.
  config.vm.network "private_network", ip: VAGRANTFILE_MYPROJECT_IP

  # Share an additional folder to the guest VM. The first argument is the path on the host to the actual folder.
  # The second argument is the path on the guest to mount the folder.
  config.vm.synced_folder "./", "/var/www/html", type: "nfs", :mount_options => ['rw', 'vers=3', 'tcp'], :linux__nfs_options => ['async']

  # Define the bootstrap file: A (shell) script that runs after first setup of your box (= provisioning)
  config.vm.provision :shell, path: "https://raw.githubusercontent.com/Darklg/BaseVagrantFile/master/bootstrap.sh", :args => VAGRANTFILE_ARGS
  # OR Local version for debug purposes
  # config.vm.provision :shell, path: "bootstrap.sh", :args => VAGRANTFILE_ARGS

  # Restart some services after mounting
  config.vm.provision :shell, run: "always", inline: <<-SHELL
  if service --status-all | grep -Fq 'apache2'; then
    sudo service apache2 restart
  fi
  if service --status-all | grep -Fq 'nginx'; then
    sudo service nginx restart
  fi
SHELL

  # Cache warming the home page
  config.vm.provision "shell", run: "always" do |s|
    s.inline = "wget -O/dev/null -q $1://$2;";
    s.args   = [ ((VAGRANTFILE_MYPROJECT_HTTPS == '1') ? 'https' : 'http'), VAGRANTFILE_MYPROJECT_DOMAIN ]


  # Hostname
  config.ssh.forward_agent = true
  config.vm.hostname = VAGRANTFILE_MYPROJECT_DOMAIN
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  if not VAGRANTFILE_MYPROJECT_DOMAINALIASES.empty?
    config.hostmanager.aliases = VAGRANTFILE_MYPROJECT_DOMAINALIASES.split
  end
end
