# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::nginx
class profile::server::phpfpm (
  Hash[String, Hash[String, Data]] $php_versions = undef,
  Array[String]                    $php_extensions_all_versions = undef,
){
  apt::ppa { 'ppa:ondrej/php': }

  $php_versions.each |$php_version, $entries| {
    @::profile::server::phpfpm::instance{ $php_version: }
    $entries['extensions'].each |$php_extension| {
      @::profile::server::phpfpm::module{ "${php_version}-${php_extension}": }
    }
    $php_extensions_all_versions.each |$php_extension| {
      @::profile::server::phpfpm::module{ "${php_version}-${php_extension}": }
    }
  }
}
