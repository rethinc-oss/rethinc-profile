node default {
  include ::profile::server::base
  include ::profile::server::mysql
  include ::profile::server::golang
  include ::profile::server::pebble
  include ::profile::server::mailhog
  class { '::profile::server::nginx':
    acme_server => 'https://localhost:14000/dir',
    acme_cacert => '/opt/pebble/minica.pem',
    acme_email => 'dummy@local.dev',
    domain_suffix => 'localdev',
  }
  include ::profile::server::phpfpm

  ::profile::server::website::php::laravel{ 'example':
    domain_www => true,
    https => true,
    php_version => '7.3',
    php_development => true,
    php_modules => ['bcmath', 'json', 'mbstring', 'xml', 'mysql', 'tokenizer'],
  }
  ::mysql::db { 'example':
      user     => 'example',
      password => 'example',
      host     => '%',
      grant    => ['ALL'],
  }
}
