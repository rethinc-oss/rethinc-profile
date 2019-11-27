# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::nginx
class profile::server::nginx (
  String $acme_server           = 'https://acme-v01.api.letsencrypt.org/directory',
  String $acme_email            = undef,
  Optional[String] $acme_cacert = undef,
  String $domain_suffix         = '',
){
  include ::stdlib
  include ::nginx

  $default_vhost_files = ['/etc/nginx/sites-enabled/default', '/etc/nginx/sites-available/default']
  file{ $default_vhost_files:
    ensure => 'absent',
  }

  $dhparam_file = '/etc/ssl/certs/dhparam2048.pem'
  exec { 'generate_dhparams':
    command => "/usr/bin/sudo /usr/bin/openssl dhparam -outform PEM -out ${dhparam_file} 2048",
    creates => '/etc/ssl/certs/dhparam2048.pem',
  }

  $default_fqdn = 'default.vhost'
  $default_cert = "/etc/nginx/${default_fqdn}.crt"
  $default_key = "/etc/nginx/${default_fqdn}.key"
  $default_log = "/var/log/nginx/${default_fqdn}.log"
  exec { 'generate_default_sslcert':
    command => "/usr/bin/sudo /usr/bin/openssl req -newkey rsa:2048 -nodes -keyout ${default_key} -x509 -days 3650 -out ${default_cert} -subj '/CN=${default_fqdn}'",
    creates => ['/etc/nginx/default.vhost.key', '/etc/nginx/default.vhost.crt']
  }

  @user { 'www-data':  ### TODO: Nicht hartcodieren sondern die variable aus der nginx klasse benutzen!!!
    gid        => 'www-data',
    groups     => [],
    membership => inclusive,
  }
  User <| title == www-data |>

  nginx::resource::server{ '000-default_http':
    use_default_location => false,
    server_name          => [ '_' ],
    listen_options       => 'default_server',
    ipv6_listen_options  => 'default_server',
    ipv6_enable          => true,
    http2                => 'on',
    index_files          => [],
    autoindex            => 'off',
    access_log           => $default_log,
    error_log            => $default_log,
    server_cfg_append    => {
      return => '444',
    },
    require              => [ File[$default_vhost_files] ],
  }

  nginx::resource::server{ '000-default_https':
    use_default_location      => false,
    server_name               => [ '_' ],
    listen_port               => 443,
    listen_options            => 'default_server',
    ipv6_enable               => true,
    ipv6_listen_port          => 443,
    ipv6_listen_options       => 'default_server',
    http2                     => 'on',
    index_files               => [],
    autoindex                 => 'off',
    access_log                => $default_log,
    error_log                 => $default_log,

    ssl                       => true,
    ssl_port                  => 443,
    ssl_cert                  => $default_cert,
    ssl_key                   => $default_key,
    ssl_session_timeout       => '1d',
    ssl_cache                 => 'shared:SSL:50m',
    ssl_session_tickets       => 'off',
    ssl_dhparam               => $dhparam_file,

    # modern configuration. tweak to your needs.
    ssl_protocols             => 'TLSv1.2',
    ssl_ciphers               => 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256',
    ssl_prefer_server_ciphers => 'on',

    # HSTS (ngx_http_headers_module is required) (15768000 seconds = 6 months)
    add_header                => {
      'Strict-Transport-Security' => 'max-age=15768000',
    },

    # OCSP Stapling ---
    # fetch OCSP records from URL in ssl_certificate and cache them
    # disable for default vhost. Reason: self signed certificate
    ssl_stapling              => false,
    ssl_stapling_verify       => false,

    server_cfg_append         => {
      return => '444',
    },
    require                   => [ File[$default_vhost_files], Exec['generate_dhparams'], Exec['generate_default_sslcert'] ],
  }


  apt::ppa { 'ppa:certbot/certbot': }

  class { 'letsencrypt':
#    package_ensure => 'latest',
    install_method => 'vcs',
    agree_tos      => true,
    config         => {
      email  => $acme_email,
      server => $acme_server,
    },
    require        => [ Class['apt::update'], Apt::Ppa['ppa:certbot/certbot'] ],
  }
}