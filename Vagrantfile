# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "rethinc-oss/baseimage-ubuntu-1804"

  config.vm.network "private_network", ip: "192.168.33.10"

  config.vm.provision "shell", path: "puppet_module_setup.rb", keep_color: true

  config.vm.synced_folder ".", "/vagrant"

end
