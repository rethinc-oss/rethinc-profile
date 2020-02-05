#!/opt/puppetlabs/puppet/bin/ruby
##########################################################################
# puppet_module_setup.rb
# @author Sebastien Varrette <Sebastien.Varrette@uni.lu>
# Time-stamp: <Mon 2017-08-21 13:01 svarrette>
#
# @description Prepare the Vagrant box to test this Puppet module
#
# Copyright (c) 2014-2017 Sebastien Varrette <Sebastien.Varrette@uni.lu>
# .             http://varrette.gforge.uni.lu
##############################################################################

require 'json'
require 'yaml'

# Load metadata
basedir   = File.directory?('/vagrant') ? '/vagrant' : Dir.pwd
jsonfile  = File.join(basedir, 'metadata.json')

error 'Unable to find the metadata.json' unless File.exist?(jsonfile)

metadata = JSON.parse(IO.read(jsonfile))
name = metadata['name'].gsub(%r{^[^\/-]+[\/-]}, '')
modulepath = `puppet config print modulepath`.chomp
moduledir = modulepath.split(':').first

librarian_puppet_cmd = '/opt/puppetlabs/puppet/bin/librarian-puppet'
git_cmd = '/usr/bin/git'

`bash -c "test ! -f #{git_cmd} && sudo apt update && sudo apt -y install git"`
`bash -c "test ! -f #{librarian_puppet_cmd} && sudo /opt/puppetlabs/puppet/bin/gem install --no-ri --no-rdoc librarian-puppet"`

`bash -c "cd #{moduledir}/.. && #{librarian_puppet_cmd} clean && rm -f Puppetfile*"`
`bash -c "test ! -f #{moduledir}/../metadata.json && ln -s /vagrant/metadata.json #{moduledir}/../"`
`sudo bash -c "cd #{moduledir}/.. && #{librarian_puppet_cmd} install --verbose"`

`bash -c "ln -s #{basedir} #{moduledir}/#{name}"`

puts "Module path: #{modulepath}"
puts "Moduledir:   #{moduledir}"
