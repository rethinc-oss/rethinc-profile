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
  Array[Hash] $cronjobs               = [],
  String $php_version                 = lookup('profile::server::nginx::site::php::version', String),
  Array[String] $php_modules          = lookup('profile::server::nginx::site::php::modules', Array[String]),
  Boolean $php_development            = lookup('profile::server::nginx::site::php::development', Boolean),
  String $php_memory_limit            = lookup('profile::server::nginx::site::php::memory_limit', String),
  String $php_upload_limit            = lookup('profile::server::nginx::site::php::upload_limit', String),
  Integer $php_execution_limit        = lookup('profile::server::nginx::site::php::execution_limit', Integer),
  String $php_location_match          = lookup('profile::server::nginx::site::php::location_match', String),
  Boolean $php_use_aws_s3             = false,
){
  if !defined(Class['profile::server::nginx']) {
    fail('You must include the nginx profile before declaring a vhost.')
  }
  if !defined(Class['profile::server::phpfpm']) {
    fail('You must include the phpfpm profile before declaring a vhost.')
  }
  unless $php_version =~ /(\d\.\d)/ {
    fail { "Mailformed php version: ${php_version}": }
  }

  $vhost_name_main = "${priority}-${domain}"
  $pool_file_socket = "unix:/run/php/${domain}.sock"

  $real_php_modules = $php_development ? { true => concat($php_modules, 'xdebug'), false => $php_modules }

  realize (::Profile::Server::Phpfpm::Instance[$php_version])

  $real_php_modules.each |$site_module| {
    realize ::Profile::Server::Phpfpm::Module["${php_version}-${site_module}"]
  }

  class { '::composer':
    command_name => 'composer',
    target_dir   => '/usr/local/bin',
    auto_update  => true,
    require => ::Profile::Server::Phpfpm::Instance[$php_version],
  }

    class { '::nodejs':
    repo_url_suffix => '13.x',
    require => Class['::composer'],
  }

  $php_admin_values_base = {
    "memory_limit"        => $php_memory_limit,
    "upload_max_filesize" => $php_upload_limit,
    "post_max_size"       => $php_upload_limit,
    "max_execution_time"  => $php_execution_limit,
    "expose_php"          => 'Off'
  }

  $php_env_values_base = $php_use_aws_s3 ? { true => { 'AWS_S3_BUCKET' => $domain }, false => {} }

  if $php_development {
    $php_admin_values_devel = {
      'xdebug.remote_enable'       => 'true',
      'xdebug.remote_connect_back' => 'true',
      'xdebug.remote_autostart'    => 'true',
      'error_reporting'            => 'E_ALL',
      'display_errors'             => 'On',
      'display_startup_errors'     => 'On',
    }

    if $php_use_aws_s3 {
      $php_env_values_devel = { 'AWS_S3_ENDPOINT' => 'http://localhost:10001' }
    }
    else {
      $php_env_values_devel = {}
    }
  } else {
    $php_admin_values_devel = {}
    $php_env_values_devel = {}
  }

  $php_admin_values = $php_admin_values_base + $php_admin_values_devel
  $php_env_values = $php_env_values_base + $php_env_values_devel

  ::profile::server::phpfpm::pool { $domain:
    pool_user => $user,
    pool_group => $user,
    pool_php_version => $php_version,
    pool_php_env_values => $php_env_values,
    pool_php_admin_values => $php_admin_values,
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
    cronjobs        => $cronjobs,
    max_body_size   => $php_upload_limit,
  }

  nginx::resource::location{ "${vhost_name_main}-php":
    ensure                    => present,
    server                    => $vhost_name_main,
    priority                  => 580,
    ssl                       => $https,
    ssl_only                  => $https,
    location                  => $php_location_match,
    index_files               => [],
    proxy                     => undef,
    fastcgi                   => $pool_file_socket,
    fastcgi_script            => undef,
    location_cfg_append       => {
      fastcgi_connect_timeout => '60s',
      fastcgi_read_timeout    => $php_execution_limit,
      fastcgi_send_timeout    => '60s',
      fastcgi_buffers         => '8 16k',
      fastcgi_buffer_size     => '32k',
    },
    try_files                 => ['$uri', '=404'],
  }
}
