require 'beaker-puppet'
require 'beaker-rspec'
require 'beaker/module_install_helper'

logger.error('LOADED MYYYYYYYYYY Spec Acceptance Helper')

install_module_on(hosts)
install_module_dependencies_on(hosts)

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    # Install module to all hosts
    hosts.each do |host|
      # install_dev_puppet_module_on(host, :source => module_root, :module_name => 'profile', :target_module_path => '/etc/puppet/modules')
      # Install dependencies
      # on(host, puppet('module', 'install', 'puppetlabs-stdlib'))

      # Add more setup code as needed
    end
  end
end
