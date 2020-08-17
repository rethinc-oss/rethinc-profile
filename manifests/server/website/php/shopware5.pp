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
define profile::server::website::php::shopware5(
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
  String $webroot                     = "${user_dir}/public",
  String $log_dir                     = '/var/log/nginx',
  Array[Hash] $cronjobs               = [],
  String $php_version                 = lookup('profile::server::nginx::site::php::version', String),
  Array[String] $php_modules          = lookup('profile::server::nginx::site::php::modules', Array[String]),
  Boolean $php_development            = lookup('profile::server::nginx::site::php::development', Boolean),
  String $php_memory_limit            = lookup('profile::server::nginx::site::php::memory_limit', String),
  String $php_upload_limit            = lookup('profile::server::nginx::site::php::upload_limit', String),
  Integer $php_execution_limit        = lookup('profile::server::nginx::site::php::execution_limit', Integer),
  String $php_location_match          = lookup('profile::server::nginx::site::php::location_match', String),
  Hash $php_env_vars                  = {},
){
  $vhost_name_main = "${priority}-${domain}"

  ::profile::server::nginx::site::php{ $title:
    domain                   => $domain,
    domain_www               => $domain_www,
    domain_primary           => $domain_primary,
    priority                 => $priority,
    https                    => $https,
    http_port                => $http_port,
    https_port               => $https_port,
    user                     => $user,
    user_dir                 => $user_dir,
    manage_user_dir          => $manage_user_dir,
    webroot                  => $webroot,
    log_dir                  => $log_dir,
    cronjobs                 => $cronjobs,
    php_version              => $php_version,
    php_modules              => $php_modules,
    php_development          => $php_development,
    php_memory_limit         => $php_memory_limit,
    php_upload_limit         => $php_upload_limit,
    php_execution_limit      => $php_execution_limit,
    php_location_match       => $php_location_match,
    php_env_vars             => $php_env_vars,
  }

  ## Deny all attems to access possible configuration files
  nginx::resource::location { "${vhost_name_main}-deny-configfiles":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 520,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '~ \.(tpl|yml|ini|log)$',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to media upload folder
  nginx::resource::location { "${vhost_name_main}-deny-upload":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 521,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '^~ /media/temp/',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to caches and log files
  nginx::resource::location { "${vhost_name_main}-deny-caches-logs":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 522,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '^~ /var/',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to root files
  nginx::resource::location { "${vhost_name_main}-deny-root":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 523,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '(autoload\.php|composer\.(json|lock|phar)|CONTRIBUTING\.md|eula.*\.txt|license\.txt|README\.md|UPGRADE-(.*)\.md|.*\.dist)$',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to shop configuration
  nginx::resource::location { "${vhost_name_main}-deny-shop-config":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 524,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/(web\/cache\/(config_\d+\.json|all.less))$',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to theme configuration
  nginx::resource::location { "${vhost_name_main}-deny-theme-config":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 525,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/themes/(.*)(.*\.lock|package\.json|Gruntfile\.js|all\.less)$',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to document files
  nginx::resource::location { "${vhost_name_main}-deny-documents":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 526,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '^~ /files/documents/',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  ## Deny access to backups
  nginx::resource::location { "${vhost_name_main}-deny-backups":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 527,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '^~ /files/backup/',
    index_files          => [],
    location_cfg_append => {
      return     => '404',
      error_page => '404 /404_error.html',
    },
  }

  # Restrict access to plugin xmls
  # rewrite, because this is the default behaviour for non-existing files and
  # makes it difficult to detect whether a plugin is installed or not by checking the files
  nginx::resource::location { "${vhost_name_main}-restrict-plugin-xmls":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 528,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '~ /custom/.*(config|menu|services|plugin)\.xml$',
    index_files          => [],
    location_cfg_append => {
      rewrite => '. /shopware.php?controller=Error&action=pageNotFoundError last'
    },
  }

  # Block direct access to ESDs, but allow the follwing download options:
  #  * 'PHP' (slow)
  #  * 'X-Accel' (optimized)
  # Also see http://wiki.shopware.com/ESD_detail_1116.html#Ab_Shopware_4.2.2
  # With Shopware 5.5 a esdKey will be generated in the installation process, please consider changing this value
  nginx::resource::location { "${vhost_name_main}-deny-esds":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 529,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '^~ /files/552211cce724117c3178e3d22bec532ec/',
    index_files          => [],
    location_cfg_append => {
      internal => ''
    },
  }

  nginx::resource::location { "${vhost_name_main}-try-files-install":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 530,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/recovery/install',
    index_files          => ['index.php'],
    try_files            => ['$uri', '/recovery/install/index.php$is_args$args'],
  }

  nginx::resource::location { "${vhost_name_main}-try-files-update":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 531,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/recovery/update',
    index_files          => [],
    raw_prepend =>
      'location /recovery/update/assets {
      }
      if (!-e $request_filename){
          rewrite . /recovery/update/index.php last;
      }',
  }

  nginx::resource::location { "${vhost_name_main}-root":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 532,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/',
    index_files          => [],
    raw_prepend =>
      'location ~* "^/themes/Frontend/(?:.+)/frontend/_public/(?:.+)\.(?:ttf|eot|svg|woff|woff2)$" {
        expires max;
        add_header Cache-Control "public";
        access_log off;
        log_not_found off;
    }

    location ~* "^/web/cache/(?:[0-9]{10})_(?:.+)\.(?:js|css)$" {
        expires max;
        add_header Cache-Control "public";
        access_log off;
        log_not_found off;
    }


    ## All static files will be served directly.
    location ~* ^.+\.(?:css|cur|js|jpe?g|gif|ico|png|svg|webp|html)$ {
        ## Defining rewrite rules
        rewrite files/documents/.* /engine last;
        rewrite backend/media/(.*) /media/$1 last;

        expires 1w;
        add_header Cache-Control "public, must-revalidate, proxy-revalidate";

        access_log off;
        # The directive enables or disables messages in error_log about files not found on disk.
        log_not_found off;

        tcp_nodelay off;
        ## Set the OS file cache.
        open_file_cache max=3000 inactive=120s;
        open_file_cache_valid 45s;
        open_file_cache_min_uses 2;
        open_file_cache_errors off;

        ## Fallback to shopware
        ## comment in if needed
        try_files $uri /shopware.php?controller=Media&action=fallback;
    }

    index shopware.php index.php;
    try_files $uri $uri/ /shopware.php$is_args$args;',
  }

  ## XML Sitemap support.
  nginx::resource::location { "${vhost_name_main}-xml-sitemap":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 533,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/sitemap.xml',
    index_files          => [],
    try_files => ['$uri', '@shopware'],
    location_cfg_append => {
      log_not_found => 'off',
      access_log    => 'off',
    },
  }

  ## XML SitemapMobile support.
  nginx::resource::location { "${vhost_name_main}-xml-sitemap-mobile":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 534,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '/sitemapMobile.xml',
    index_files          => [],
    try_files => ['$uri', '@shopware'],
    location_cfg_append => {
      log_not_found => 'off',
      access_log    => 'off',
    },
  }

  Nginx::Resource::Location<|title == "${vhost_name_main}-robots"|> {
    try_files => ['$uri', '@shopware'],
  }

  # Don't polute logs with messages about /favicon.ico
  nginx::resource::location { "${vhost_name_main}-shopware":
    ensure               => present,
    server               => $vhost_name_main,
    priority             => 535,
    ssl                  => $https,
    ssl_only             => $https,
    location             => '@shopware',
    index_files          => [],
    location_cfg_append => {
      rewrite => '/ /shopware.php'
    },
  }
}
