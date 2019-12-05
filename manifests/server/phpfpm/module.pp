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

  unless defined(::Package[$extension_package]) {
    package { $extension_package:
      ensure => present,
      require => ::Profile::Server::Phpfpm::Instance[$php_version]
    }
  }
}
