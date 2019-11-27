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
