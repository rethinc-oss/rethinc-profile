
define profile::server::phpfpm::module(
){
  if $title =~ /(\d\.\d)-(\w+)/ {
    $extension_php_version = "${1}"
    $extension_name        = "${2}"
    $extension_package     = "php${extension_php_version}-${extension_name}"
  } else {
    fail { "Mailformed title: ${title}": }
  }

  unless defined(::Package[$extension_package]) {
    notify { "Realizing extension: ${extension_package}": }
    package { $extension_package:
      ensure => present,
    }
  }
}
