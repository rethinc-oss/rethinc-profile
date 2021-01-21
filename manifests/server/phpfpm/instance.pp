define profile::server::phpfpm::instance(
){
  if !defined(Class['profile::server::phpfpm']) {
    fail('You must include the phpfpm profile before declaring phpfpm instance.')
  }

  if $title =~ /(\d\.\d)/ {
    $php_version = "${1}"
    $php_package = "php${php_version}-fpm"
  } else {
    fail { "Mailformed title: ${title}": }
  }

  $default_pool = "/etc/php/${php_version}/fpm/pool.d/www.conf"

  ensure_packages([$php_package])

  service { $php_package:
    ensure  => 'running',
    enable  => true,
    require => Package[$php_package],
  }

  file { $default_pool:
    ensure  => absent,
    require => Package[$php_package],
    notify  => Service[$php_package]
  }

  systemd::dropin_file { "${php_package}-dropin":
    unit    => "${php_package}.service",
    name    => 'local.conf',
    content => epp('profile/phpfpm/systemd.dropin.epp', {
      php_version => $php_version,
    }),
    require => Package[$php_package],
    notify  => Service[$php_package]
  }
}
