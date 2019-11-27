# define: profile::server::nginx::site::static
#
# This definition creates a virtual host
#
# Parameters:
#   [*domain*]                     - The base domain of the virtual host (e.g. 'example.com')
#   [*domain_www*]                 - BOOL value to enable/disable creating a virtual host for "www.${domain}"; default: true
#   [*domain_primary*]             - Which domain to redirect to (base|www), if $domain_www is enabled; default: www
#   [*https*]                      - BOOL value to enable listening on port 443; default: true
#
define profile::server::nginx::site::static(
  String $domain                      = $title,
  Boolean $domain_www                 = true,
  Enum['base', 'www'] $domain_primary = 'www',
  Integer $priority                   = 100,
  Boolean $https                      = true,
  Integer $http_port                  = 80,
  Integer $https_port                 = 443,
  String $user                        = $domain,
  String $user_dir                    = "/var/www/${domain}",
  String $webroot                     = "${user_dir}/htdocs",
  String $log_dir                     = '/var/log/nginx',
){
  if !defined(Class['profile::server::nginx']) {
    fail('You must include the nginx profile before declaring a vhost.')
  }

  $real_domain                = "${domain}.${::profile::server::nginx::domain_suffix}"
  $primary_domain             = ($domain_www and $domain_primary == www) ? { true => "www.${real_domain}", false => $real_domain }
  $secondary_domain           = $domain_www ? { true => $domain_primary ? { www => $real_domain, base => "www.${real_domain}"}, false => undef }

  $vhost_name_main            = "${priority}-${domain}"
  $vhost_name_redirect_http   = "${vhost_name_main}-redirect-http"
  $vhost_name_redirect_https  = "${vhost_name_main}-redirect-https"

  # if the primary vhost is https based, redirect from http for both the primary and secondary the domain, else just from the secondary domain.
  # if there is no secondary domain, skip it.
  $http_redirect_servernames  = delete_undef_values( $https ? { true => [$primary_domain, $secondary_domain], false => [$secondary_domain] } )

  # if there is a secondary domain and the primary vhost is https based, redirect the https based secondary domain to the primary domain.
  $https_redirect_servernames = delete_undef_values( $https ? { true => [$secondary_domain], false => [] } )

  $redirect_protocol          = $https ? { true => 'https://', false => 'http://' }
  $redirect_target            = "301 ${redirect_protocol}${primary_domain}\$request_uri"

  $main_access_log            = "${log_dir}/${real_domain}_access.log"
  $main_error_log             = "${log_dir}/${real_domain}_error.log"
  $redirect_access_log        = "${log_dir}/${real_domain}_redirect_access.log"
  $redirect_error_log         = "${log_dir}/${real_domain}_redirect_error.log"

  $https_certificate          = "/etc/letsencrypt/live/${real_domain}/cert.pem"
  $https_certificate_key      = "/etc/letsencrypt/live/${real_domain}/privkey.pem"

  # define the user account for the webpage
  user { $user:
    ensure     => 'present',
    home       => $user_dir,
    managehome => true,
    before     => User['www-data'],
  }

  User <| title == www-data |> { groups +> $user }

  file { $webroot:
    ensure  => 'directory',
    owner   => $user,
    group   => $user,
    mode    => '0750',
    require => User[$user]
  }

  #
  # Redirecting HTTP-VHost
  #

  # define the redirecting http vhost
  if ( !empty($http_redirect_servernames)) {
    profile::server::nginx::internal::redirect_vhost{ $vhost_name_redirect_http:
      servernames     => $http_redirect_servernames,
      https           => false,
      port            => $http_port,
      webroot         => $webroot,
      redirect_target => $redirect_target,
      access_log      => $redirect_access_log,
      error_log       => $redirect_error_log,
      before          => $https ? { true => Exec['nginx_reload'], false => []}, # lint:ignore:selector_inside_resource
    }
  } else {
    nginx::resource::server{ $vhost_name_redirect_http:
      ensure => absent,
    }
  }

  #
  # Redirecting HTTPS-VHost
  #

  if ( $https and !empty($https_redirect_servernames) ) {
    profile::server::nginx::internal::redirect_vhost{ $vhost_name_redirect_https:
      servernames           => $https_redirect_servernames,
      https                 => true,
      https_certificate     => $https_certificate,
      https_certificate_key => $https_certificate_key,
      port                  => $https_port,
      webroot               => $webroot,
      redirect_target       => $redirect_target,
      access_log            => $redirect_access_log,
      error_log             => $redirect_error_log,
      require               => Letsencrypt::Certonly[$real_domain],
    }
  } else {
    nginx::resource::server{ $vhost_name_redirect_https:
      ensure => absent,
      before => Exec['nginx_reload'],
    }
  }

  #
  # Main  HTTP(S)-VHost
  #

  profile::server::nginx::internal::main_vhost{ $vhost_name_main:
    servernames           => [$primary_domain],
    https                 => $https,
    https_certificate     => $https_certificate,
    https_certificate_key => $https_certificate_key,
    port                  => $https ? { true => $https_port, false => $http_port }, # lint:ignore:selector_inside_resource
    webroot               => $webroot,
    access_log            => $main_access_log,
    error_log             => $main_error_log,
    require               => $https ? { true => Letsencrypt::Certonly[$real_domain], false => [] }, # lint:ignore:selector_inside_resource
  }

  #
  # Letsencrypt certificate generation
  #

  if ( $https ) {
    # TODO: if running reload, else restart
    exec { 'nginx_reload':
      command => '/usr/bin/sudo /bin/systemctl restart nginx.service',
    }

    letsencrypt::certonly { $real_domain:
      domains       => delete_undef_values( [$primary_domain, $secondary_domain] ),
      plugin        => 'webroot',
      webroot_paths => [$webroot],
      environment   => $::profile::server::nginx::acme_cacert != undef ? {
        true  => ["REQUESTS_CA_BUNDLE=${::profile::server::nginx::acme_cacert}"],
        false => [] },
      require       => Exec['nginx_reload'],
    }
  }
}