# define: profile::server::nginx::site::php
#
# This definition creates a virtual host
#
# Parameters:
#   [*domain*]                     - The base domain of the virtual host (e.g. 'example.com')
#   [*domain_www*]                 - BOOL value to enable/disable creating a virtual host for "www.${domain}"; default: true
#   [*domain_primary*]             - Which domain to redirect to (base|www), if $domain_www is enabled; default: www
#   [*https*]                      - BOOL value to enable listening on port 443; default: true
#
define profile::server::website::php::laravel(
  String $domain                      = $title,
  Boolean $domain_www                 = true,
  Enum['base', 'www'] $domain_primary = 'www',
  Integer $priority                   = 100,
  Boolean $https                      = true,
  Integer $http_port                  = 80,
  Integer $https_port                 = 443,
  String $user                        = $domain,
  String $user_dir                    = "/var/www/${domain}",
  Boolean $manage_user_dir            = true,
  String $webroot_parent_dir          = $user_dir,
  String $webroot                     = "${webroot_parent_dir}/public",
  String $log_dir                     = '/var/log/nginx',
  Array[Hash] $cronjobs               = [],
  String $php_version                 = lookup('profile::server::nginx::site::php::version', String),
  Array[String] $php_modules          = lookup('profile::server::nginx::site::php::modules', Array[String]),
  Boolean $php_development            = lookup('profile::server::nginx::site::php::development', Boolean),
  String $php_memory_limit            = lookup('profile::server::nginx::site::php::memory_limit', String),
  String $php_upload_limit            = lookup('profile::server::nginx::site::php::upload_limit', String),
  Integer $php_execution_limit        = lookup('profile::server::nginx::site::php::execution_limit', Integer),
  String $php_location_match          = lookup('profile::server::nginx::site::php::location_match', String),
  Hash $php_env_vars                  = {},
){
  $vhost_name_main = "${priority}-${domain}"

  ::profile::server::nginx::site::php{ $title:
    domain                   => $domain,
    domain_www               => $domain_www,
    domain_primary           => $domain_primary,
    priority                 => $priority,
    https                    => $https,
    http_port                => $http_port,
    https_port               => $https_port,
    user                     => $user,
    user_dir                 => $user_dir,
    manage_user_dir          => $manage_user_dir,
    webroot_parent_dir       => $webroot_parent_dir,
    webroot                  => $webroot,
    log_dir                  => $log_dir,
    cronjobs                 => $cronjobs,
    php_version              => $php_version,
    php_modules              => $php_modules,
    php_development          => $php_development,
    php_memory_limit         => $php_memory_limit,
    php_upload_limit         => $php_upload_limit,
    php_execution_limit      => $php_execution_limit,
    php_location_match       => $php_location_match,
    php_env_vars             => $php_env_vars,
  }

  nginx::resource::location { "${vhost_name_main}-index-frontend":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 510,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '= /',
    index_files          => ['index.php'],
  }

  #try to get file directly, try it as a directory or fall back to php
  nginx::resource::location { "${vhost_name_main}-try-files":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 512,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/',
    index_files          => [],
    try_files            => ['$uri', '$uri/', '/index.php?$query_string'],
  }
}
