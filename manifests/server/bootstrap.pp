# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::bootstrap
class profile::server::bootstrap (
  Boolean $unattended_upgrades,
){
  if (!$unattended_upgrades)
  {
    systemd::dropin_file { 'apt-daily.timer.conf':
      unit   => 'apt-daily.timer',
      source => "puppet:///modules/${module_name}/apt/apt-daily.timer.conf",
    }
    ~> service {'apt-daily.timer':
      ensure   => false,
      enable   => false,
    }
  }
  -> exec { 'boostrap_wait_for_unattended_upgrades':
    command => '/usr/bin/systemd-run --property="After=apt-daily.service apt-daily-upgrade.service" --wait /bin/true',
    unless  => '/usr/bin/test -f /var/cache/apt/.intial_update_done',
  }
  -> exec { 'bootstrap_initial_apt_update':
    command => '/usr/bin/apt update && /usr/bin/apt install -y software-properties-common',
    unless  => '/usr/bin/test -f /var/cache/apt/.intial_update_done',
  }
  -> file { '/var/cache/apt/.intial_update_done':
    ensure => present,
  }
}
