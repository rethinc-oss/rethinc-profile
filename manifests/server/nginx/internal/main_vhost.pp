define profile::server::nginx::internal::main_vhost(
  String $vhost                           = $title,
  Array[String] $servernames              = undef,
  Boolean $https                          = undef,
  Optional[String] $https_certificate     = undef,
  Optional[String] $https_certificate_key = undef,
  Integer $port                           = undef,
  String $webroot                         = undef,
  String $access_log                      = undef,
  String $error_log                       = undef,
){
  nginx::resource::server{ $vhost:
    use_default_location      => false,
    server_name               => $servernames,
    listen_port               => $port,
    listen_options            => '',
    ipv6_enable               => true,
    ipv6_listen_port          => $port,
    ipv6_listen_options       => '',
    http2                     => $https ? { true => 'on', false => 'off' }, # lint:ignore:selector_inside_resource
    index_files               => [],
    autoindex                 => 'off',
    access_log                => $access_log,
    error_log                 => $error_log,
    www_root                  => $webroot,

    ssl                       => $https,
    ssl_port                  => $https ? { true => $port, false => undef }, # lint:ignore:selector_inside_resource
    ssl_cert                  => $https_certificate,
    ssl_key                   => $https_certificate_key,
    ssl_session_timeout       => '1d',
    ssl_cache                 => 'shared:SSL:50m',
    ssl_session_tickets       => 'off',
    ssl_dhparam               => $::profile::server::nginx::dhparam_file,

    # modern configuration. tweak to your needs.
    ssl_protocols             => 'TLSv1.2',
    ssl_ciphers               => 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256',
    ssl_prefer_server_ciphers => 'on',

    # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
    add_header                => $https ? { # lint:ignore:selector_inside_resource
      true  => { 'Strict-Transport-Security' => 'max-age=15768000' },
      false => undef,
    },
  }
}
