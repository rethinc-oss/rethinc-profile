# This class manages the common base configuration for all servers. That is:
#
#   - it configures the core location and language settings of a server
#     (system locale, keyboard layout, timezone).
#   - It configures the apt update & upgrade policy.
#   - It sets up time synchronization
#   - It creates the central system-management user.
#   - It install a few core system-management utilities.
#
# @summary Manages the common base configuration for all servers
#
# @example
#   include profile::server::base
#
# @param timezone
#   The timezone used for calculting the local time. The list of valid
#   values can be printed with: timedatectl list-timezones. Default value:
#   Europe/Berlin.
# @param keyboard_layout
#   The keyboard layout top use. Default value: de.
# @param locale
#   The system locale. Default value: en_US.UTF-8.
# @param management_user_name
#   The descriptive name of the system-management user. Default value: System Operator.
# @param management_user_login
#   The login name of the system-management user. Default value: sysop
# @param management_user_password
#   The password of the system-management user. Default value: n/a.
# @param management_user_addon_groups
#   An array of groups, the system-management user should be a member of in addition to
#   the default group memberships assigned at user creation. By default there is one
#   group specified, its value is looked up from the profile-level hiera variable
#   profile::server::management_group. Default value [operator]
# @param management_user_public_keys
#   An array of unique values (usualy email addresses). The values are looked up as
#   keys in the profile-level hiera variable profile::server::ssh::keys. The keys are
#   added as authorized public ssh-keys:
#
#     profile::server::ssh::keys:
#       alice@example.com:
#         type: ssh-ed25519
#         key: AAAAC3NzaC1lZdeF54E5AAAAIBKQkiccEOf3yww62zTQwZSPX96eL7zVqPmAF56lnW
#         comment: Alice (Login Key)
#       bob@example.com:
#         type: ssh-ed25519
#         key: AAAAC3NzaC1lZdeF54E5AAAAIBKQkiccEOf3yww62zTQwZSPX96eL7zVqPmAF56lnW
#         comment: Bob (Login Key)
#
class profile::server::base (
  String $timezone,
  String $keyboard_layout,
  String $locale,
  String $management_user_name,
  String $management_user_login,
  String $management_user_password,
  Array[String] $management_user_groups,
  Optional[Array[String]] $management_user_addon_groups = undef,
  Optional[Array[String]] $management_user_public_keys = undef,
  Optional[Hash[String, Hash]] $public_key_definitions = lookup('profile::server::ssh::keys', Optional[Hash[String, Hash]], undef, undef)
  ){

  include ::stdlib

  ### APT & System-Update Configuration

  # Ensure that the APT package index is uptodate
  class { '::profile::server::bootstrap':
    stage => setup,
  }

  class { '::apt':
    update => {
      frequency => 'daily',
    },
  }

  ### Configure the core location and language settings

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

  ### Configure the timezone and set up time synchronization via NTP

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

  ### Create the system-management user

  group { $management_user_addon_groups:
    ensure => present,
  }

  $opt_management_user_pw = str2sha512shadow($management_user_password)

  $opt_management_user_groups = $management_user_groups + $management_user_addon_groups
  user { $management_user_login:
    ensure     => present,
    groups     => $opt_management_user_groups,
    comment    => $management_user_name,
    managehome => true,
    password   => Sensitive($opt_management_user_pw),
    require    => [Group[$management_user_addon_groups]],
  }

  if ($management_user_public_keys != undef) {
    $management_user_public_keys.each |String $for_user| {
      if ($public_key_definitions == undef or $public_key_definitions[$for_user] == undef) {
        fail("Key for ${for_user} not found!")
      } else {
        ssh_authorized_key { "${management_user_login}(${for_user})":
          ensure => present,
          user   => $management_user_login,
          type   => $public_key_definitions[$for_user]['type'],
          key    => $public_key_definitions[$for_user]['key'],
          name   => $public_key_definitions[$for_user]['comment'],
        }
      }
    }
  }

  ### Install core utility packages

  $utilities = ['htop', 'nano', 'mc', 'dnsutils', 'bash-completion', 'software-properties-common', 'screen', 'psmisc', 'net-tools']
  package { $utilities: ensure => installed }

  file { '/etc/nanorc':
    path    => '/etc/nanorc',
    mode    => '0644',
    source  => 'puppet:///modules/profile/nano/nanorc',
    require => Package['nano'],
  }
}
