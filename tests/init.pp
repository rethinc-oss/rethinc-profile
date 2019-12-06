node default {
    include ::profile::server::base
    include ::profile::server::mysql
    include ::profile::server::pebble
    include ::profile::server::nginx
    include ::profile::server::phpfpm
    ::profile::server::website::php::evoim{ 'example.com':
      domain_www => true,
      https => true,
      php_version => '7.3',
      php_development => true,
      php_modules => ['imagick'],
    }
    mysql::db { 'example.com':
        user     => 'example.com',
        password => 'example.com',
        host     => 'localhost',
        grant    => ['ALL'],
    }
}
