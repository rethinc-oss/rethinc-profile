# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::nginx
class profile::server::phpfpm (
  Hash $php_versions = {
    '7.1' => {
      extensions => ['bz2', 'curl', 'gd', 'json', 'mbstring', 'mysql', 'opcache', 'readline', 'zip', 'recode', 'snmp', 'soap'],
    },
    '7.2' => {
      extensions => ['bz2', 'curl', 'gd', 'json', 'mbstring', 'mysql', 'opcache', 'readline', 'zip', 'recode', 'snmp', 'soap'],
    },
    '7.3' => {
      extensions => ['bz2', 'curl', 'gd', 'json', 'mbstring', 'mysql', 'opcache', 'readline', 'zip', 'recode', 'snmp', 'soap'],
    },
  },
){
  apt::ppa { 'ppa:ondrej/php': }

  $php_versions.each |$php_version, $entries| {
    @::profile::server::phpfpm::instance{ $php_version: }
    $entries['extensions'].each |$php_extension| {
      @::profile::server::phpfpm::module{ "${php_version}-${php_extension}": }
    }
  }
}
