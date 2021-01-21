define profile::server::phpfpm::module(
){
  $modules = lookup('profile::server::phpfpm::modules', Hash[String, Array[String]])

  if $title =~ /(\d\.\d)-(\w+)/ {
    $php_version    = "${1}"
    $extension_name = "${2}"
  } else {
    fail { "Mailformed title: ${title}": }
  }

  if ('*' in $modules[$extension_name]) {
    $extension_php_version = ''
  } else {
    $extension_php_version = $php_version
  }

  $extension_package = "php${extension_php_version}-${extension_name}"

  case $extension_name {
    'pdflib':  {
      unless defined(::Profile::Server::Phpfpm::Modules::Pdflib['pdflib']) {
        profile::server::phpfpm::modules::pdflib{'pdflib':
          php_version => $php_version,
          require     => ::Profile::Server::Phpfpm::Instance[$php_version]
        }
      }
    }
    default: {
      unless defined(::Package[$extension_package]) {
        package { $extension_package:
          ensure  => present,
          require => ::Profile::Server::Phpfpm::Instance[$php_version]
        }

        if $extension_package == 'php-imagick' {
            file { '/etc/ImageMagick-6/policy.xml':
              ensure  => present,
              source  => 'puppet:///modules/profile/imagick/policy.xml',
              require => [ Package[$extension_package]],
            }
        }
      }
    }
  }
}
