class profile::server::pebble {
  include ::stdlib

  $pebble_version = 'v2.3.1'

  exec { 'create_pebble_source_dir':
    command => '/usr/bin/mkdir -p /opt/go/src/github.com/letsencrypt/',
    creates => '/opt/go/src/github.com/letsencrypt/',
    onlyif  => '/usr/bin/test ! -d /opt/go/src/github.com/letsencrypt/',
  }

  exec { 'clone_pebble_repo':
    command => '/usr/bin/git clone https://github.com/letsencrypt/pebble.git',
    cwd     => '/opt/go/src/github.com/letsencrypt/',
    creates => '/opt/go/src/github.com/letsencrypt/pebble/',
    onlyif  => '/usr/bin/test ! -d /opt/go/src/github.com/letsencrypt/pebble/.git',
    require => [ Exec['create_pebble_source_dir'] ],
  }

  exec { 'fetch_pebble_repo':
    command => '/usr/bin/git fetch',
    cwd     => '/opt/go/src/github.com/letsencrypt/pebble/',
    onlyif  => "/usr/bin/test -d /opt/go/src/github.com/letsencrypt/pebble/.git -a $(/usr/bin/git describe --tags) != '${pebble_version}'",
    require => [ Exec['clone_pebble_repo'] ],
  }

  exec { 'checkout_pebble_version':
    command => "/usr/bin/git checkout -f ${pebble_version} && rm -f /opt/go/bin/pebble && rm -f /opt/go/bin/pebble-challtestsrv",
    cwd     => '/opt/go/src/github.com/letsencrypt/pebble/',
    onlyif  => "/usr/bin/test $(/usr/bin/git describe --tags) != '${pebble_version}'",
    require => [ Exec['fetch_pebble_repo'] ],
  }

  exec { 'install_pebble':
    command     => '/usr/bin/go install -mod=readonly ./...',
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    cwd         => '/opt/go/src/github.com/letsencrypt/pebble/',
    onlyif      => '/usr/bin/test ! -f /opt/go/bin/pebble',
    creates     => '/opt/go/bin/pebble',
    require     => [ Package['golang-go'], Exec['checkout_pebble_version'] ],
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
