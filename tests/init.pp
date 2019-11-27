node default {
    include ::profile::server::base
    include ::profile::server::mysql
    include ::profile::server::pebble
    include ::profile::server::nginx
    include ::profile::server::phpfpm
    ::profile::server::nginx::site::php{ 'example.com': domain_www => true, https => true, site_php_version => '7.3' }
    mysql::db { 'example.com':
        user     => 'example.com',
        password => 'example.com',
        host     => 'localhost',
        grant    => ['ALL'],
    }
}
