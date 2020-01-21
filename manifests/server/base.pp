# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::base
class profile::server::base (
  String $timezone,
  String $keyboard_layout,
  String $locale,
  String $management_user_name,
  String $management_user_login,
  String $management_user_password,
  Array[String] $management_user_public_keys = [],
  ){

  include ::stdlib

  # Ensure that the APT package index is uptodate
  class { '::profile::server::bootstrap':
    stage => setup,
  }

  class { '::apt':
    update => {
      frequency => 'daily',
    },
  }

  class { 'locales':
    default_locale => $locale,
    locales        => ["${locale} UTF-8"],
    lc_all         => $locale,
  }

  $console_data_pkgs = ['console-data', 'unicode-data']
  package { $console_data_pkgs: ensure => 'installed' }

  file { '/etc/default/keyboard':
    ensure  => 'present',
    content => template('profile/default_keyboard.erb'),
    require => Package[$console_data_pkgs]
  }

  class { 'timezone':
    timezone => $timezone,
    hwutc    => true,
  }

  service { 'systemd-timesyncd':
    ensure   => false,
    provider => 'systemd',
    enable   => false,
  }

  $salt = fqdn_rand_string(16, undef, "User[${management_user_login}]")
  $pw = pw_hash($management_user_password, 'SHA-512',$salt)
  user { $management_user_login:
    ensure     => present,
    groups     => ['adm', 'cdrom', 'dip', 'plugdev', 'lpadmin', 'sambashare', 'ssh'],
    comment    => $management_user_name,
    managehome => true,
    password   => Sensitive($pw),
    require    => Group['ssh'],
  }

  $key_definitions = lookup('ssh::keys', Array[String], undef, [])

  $management_user_public_keys.each |String $for_user| {
    if ($key_definitions[$for_user] == undef) {
      warn("Key for ${key_definitions[$for_user]} not found!")
    } else {
      ssh_authorized_key { $for_user:
        ensure => present,
        user   => $management_user_login,
        type   => $key_definitions[$for_user]['type'],
        key    => $key_definitions[$for_user]['key'],
        name   => $key_definitions[$for_user]['comment'],
      }
    }
  }

  class { '::chrony':
    servers          => {
      'ptbtime1.ptb.de' => ['iburst'],
      'ptbtime2.ptb.de' => ['iburst'],
      'ptbtime3.ptb.de' => ['iburst'],
      'de.pool.ntp.org' => ['iburst'],
    },
    makestep_updates => -1,
    makestep_seconds => 1,
  }

  $utilities = ['htop', 'nano', 'mc', 'dnsutils', 'bash-completion', 'software-properties-common', 'screen', 'psmisc', 'net-tools']
  package { $utilities: ensure => installed }
}
