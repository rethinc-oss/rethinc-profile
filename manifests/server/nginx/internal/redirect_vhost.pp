define profile::server::nginx::internal::redirect_vhost(
  String $vhost                           = $title,
  Array[String] $servernames              = undef,
  Boolean $https                          = undef,
  Optional[String] $https_certificate     = undef,
  Optional[String] $https_certificate_key = undef,
  Integer $port                           = undef,
  String $webroot                         = undef,
  String $redirect_target                 = undef,
  String $access_log                      = undef,
  String $error_log                       = undef,
){
  profile::server::nginx::internal::main_vhost{ $vhost:
    servernames           => $servernames,
    https                 => $https,
    https_certificate     => $https_certificate,
    https_certificate_key => $https_certificate_key,
    port                  => $port,
    webroot               => $webroot,
    access_log            => $access_log,
    error_log             => $error_log,
  }

  nginx::resource::location{ "${vhost}-token-directory":
    ensure      => present,
    server      => $vhost,
    priority    => 501,
    ssl         => $https,
    ssl_only    => $https,
    location    => '^~ /.well-known/',
    index_files => [],
    raw_append  => [
      'break;',
    ]
  }

  nginx::resource::location{ "${vhost}-root":
    ensure              => present,
    server              => $vhost,
    priority            => 502,
    ssl                 => $https,
    ssl_only            => $https,
    location            => '/',
    index_files         => [],
    location_cfg_append => {
      return => $redirect_target,
    },
  }
}
