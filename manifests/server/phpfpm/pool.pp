define profile::server::phpfpm::pool(
  String $pool_name = $title,
  String $pool_user = $pool_name,
  String $pool_group = $pool_name,
  String $pool_php_version = undef,
  String $pool_conf_dir = "/etc/php/${pool_php_version}/fpm/pool.d",
  Hash $pool_php_env_values = {},
  Hash $pool_php_admin_values = {},
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
      user => $pool_user,
      group => $pool_group,
      pool_php_env_values => $pool_php_env_values,
      pool_php_admin_values => $pool_php_admin_values,
    }),
    require => Package[$pool_fpm_service],
    notify  => Service[$pool_fpm_service]
  }
}
