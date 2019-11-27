# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::bootstrap
class profile::server::bootstrap {
  exec { 'apt update':
    command => '/usr/bin/apt update',
    unless  => '/usr/bin/test -f /var/cache/apt/.intial_update_done',
    before  => File['/var/cache/apt/.intial_update_done'],
  }

  file { '/var/cache/apt/.intial_update_done':
    ensure  => present,
  }
}
