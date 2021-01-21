# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "rethinc-oss/baseimage-ubuntu"
  config.vm.box_version = ">= 2004.01, <= 2004.99"

#  config.vm.network "private_network", ip: "192.168.33.10"
  config.vm.network "private_network", type: "dhcp"

  config.vm.provision "shell", path: "puppet_module_setup.rb", keep_color: true

  config.vm.synced_folder ".", "/vagrant"

end
