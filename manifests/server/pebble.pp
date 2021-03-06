class profile::server::pebble {
  include ::stdlib

  $pebble_version = 'v2.0.2'

  exec { 'download_pebble':
    command     => '/usr/bin/go get -d -u github.com/letsencrypt/pebble/...',
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    creates     => '/opt/go/src/github.com/letsencrypt/pebble/',
    require     => [ Package['golang-go'] ],
  }

  exec { 'checkout_pebble':
    command     => "/usr/bin/git checkout ${pebble_version} && rm -f /opt/ho/bin/pebble && rm -f /opt/ho/bin/pebble-challtestsrv",
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    cwd         => '/opt/go/src/github.com/letsencrypt/pebble/',
    onlyif      => "/usr/bin/test $(/usr/bin/git describe --tags) != '${pebble_version}'",
    require     => [ Exec['download_pebble'] ],
  }

  exec { 'install_pebble':
    command     => '/usr/bin/go install -mod=readonly ./...',
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    cwd         => '/opt/go/src/github.com/letsencrypt/pebble/',
    creates     => '/opt/go/bin/pebble',
    require     => [ Exec['checkout_pebble'] ],
    notify      => Systemd::Unit_file['pebble.service']
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
    require => [File['/opt/pebble/config.json'], File['/opt/pebble/cert.pem'], File['/opt/pebble/key.pem'], File['/opt/pebble/minica.pem'], Exec['install_pebble']],
  }
}
