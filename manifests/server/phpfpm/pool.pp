define profile::server::phpfpm::pool(
  String $pool_name = $title,
  String $pool_php_version = undef,
  String $pool_conf_dir = "/etc/php/${pool_php_version}/fpm/pool.d"
){
  unless $pool_php_version =~ /(\d\.\d)/ {
    fail { "Mailformed version in pool resource[${pool_name}]: ${pool_php_version}": }
  }

  $pool_conf_file   = "${pool_conf_dir}/${pool_name}.conf"
  $pool_fpm_service = "php${pool_php_version}-fpm"

  file { $pool_conf_file:
    ensure  => present,
    content => epp('profile/phpfpm/pool.conf.epp', {
      name => $pool_name,
    }),
    notify  => Service[$pool_fpm_service]
  }
}