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
define profile::server::nginx::site::php(
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
  if !defined(Class['profile::server::nginx']) {
    fail('You must include the nginx profile before declaring a vhost.')
  }
  if !defined(Class['profile::server::phpfpm']) {
    fail('You must include the phpfpm profile before declaring a vhost.')
  }
  unless $site_php_version =~ /(\d\.\d)/ {
    fail { "Mailformed php version: ${site_php_version}": }
  }

  $vhost_name_main = "${priority}-${domain}"
  $pool_file_socket = "unix:/run/php/${domain}.sock"

  realize (::Profile::Server::Phpfpm::Instance[$site_php_version])

  $site_php_modules.each |$site_module| {
    realize ::Profile::Server::Phpfpm::Module["${site_php_version}-${site_module}"]
  }

  ::profile::server::phpfpm::pool { $domain:
    pool_user => $user,
    pool_group => $user,
    pool_php_version => '7.3',
  }

  ::profile::server::nginx::site::static{ $title:
    domain          => $domain,
    domain_www      => $domain_www,
    domain_primary  => $domain_primary,
    priority        => $priority,
    https           => $https,
    http_port       => $http_port,
    https_port      => $https_port,
    user            => $user,
    user_dir        => $user_dir,
    manage_user_dir => $manage_user_dir,
    webroot         => $webroot,
    log_dir         => $log_dir,
  }

  nginx::resource::location{ "${vhost_name_main}-php":
    ensure                    => present,
    server                    => $vhost_name_main,
    priority                  => 580,
    ssl                       => $https,
    ssl_only                  => $https,
    location                  => '~ \.php$',
    index_files               => [],
    proxy                     => undef,
    fastcgi                   => $pool_file_socket,
    fastcgi_script            => undef,
    location_cfg_append       => {
      fastcgi_connect_timeout => '3m',
      fastcgi_read_timeout    => '3m',
      fastcgi_send_timeout    => '3m',
    },
    try_files                 => ['$uri', '=404'],
  }
}
