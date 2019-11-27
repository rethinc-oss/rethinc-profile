class profile::server::pebble {
  include ::stdlib

  apt::ppa { 'ppa:longsleep/golang-backports': }

  package{ 'golang-go':
    ensure  => present,
    require => [ Class['apt::update'], Apt::Ppa['ppa:longsleep/golang-backports'] ],
  }

  exec { 'install_pebble':
    command     => '/usr/bin/go get -u github.com/letsencrypt/pebble/...',
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    creates     => '/opt/go/src/github.com/letsencrypt/pebble/',
    logoutput   => true,
    require     => [ Package['golang-go'] ],
  }

  file { '/opt/pebble':
    ensure  => directory,
    recurse => true,
  }

  file { '/opt/pebble/config.json':
    ensure  => present,
    source  => 'puppet:///modules/profile/pebble/config.json',
    require => [ File['/opt/pebble']],
  }

  file { '/opt/pebble/cert.pem':
    ensure  => present,
    source  => 'puppet:///modules/profile/pebble/cert.pem',
    require => [ File['/opt/pebble']],
  }

  file { '/opt/pebble/key.pem':
    ensure  => present,
    source  => 'puppet:///modules/profile/pebble/key.pem',
    require => [ File['/opt/pebble']],
  }

  file { '/opt/pebble/minica.pem':
    ensure  => present,
    source  => 'puppet:///modules/profile/pebble/minica.pem',
    require => [ File['/opt/pebble']],
  }

  systemd::unit_file { 'pebble.service':
    source  => 'puppet:///modules/profile/pebble/pebble.service',
    enable  => true,
    active  => true,
    require => [File['/opt/pebble/config.json'], File['/opt/pebble/cert.pem'], File['/opt/pebble/key.pem'], File['/opt/pebble/minica.pem']],
  }
}
