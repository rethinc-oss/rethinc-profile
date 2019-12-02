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
define profile::server::nginx::site::evoim(
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
  String $webroot                     = "${user_dir}/htdocs",
  String $log_dir                     = '/var/log/nginx',
  String $site_php_version            = undef,
  Array[String] $site_php_modules     = [],
){
    $vhost_name_main = "${priority}-${domain}"

  ::profile::server::nginx::site::php{ $title:
    domain           => $domain,
    domain_www       => $domain_www,
    domain_primary   => $domain_primary,
    priority         => $priority,
    https            => $https,
    http_port        => $http_port,
    https_port       => $https_port,
    user             => $user,
    user_dir         => $user_dir,
    manage_user_dir  => $manage_user_dir,
    webroot          => $webroot,
    log_dir          => $log_dir,
    site_php_version => $site_php_version,
    site_php_modules => $site_php_modules,
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

  nginx::resource::location { "${vhost_name_main}-index-manager":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 511,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '= /manager/',
    index_files          => ['index.php'],
  }

  #try to get file directly, try it as a directory or fall back to modx
  nginx::resource::location { "${vhost_name_main}-try-files":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 512,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/',
    index_files          => [],
    try_files            => ['$uri', '$uri/', '@modx'],
  }

  nginx::resource::location { "${vhost_name_main}-rewrite-to-index":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 513,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '@modx',
    index_files          => [],
    rewrite_rules        => ['^/(.*)$ /index.php?q=$1&$args'],
  }
}
