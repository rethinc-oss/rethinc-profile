# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::nginx
class profile::server::phpfpm (
  Array[String] $versions                     = undef,
  Hash[String, Array[String]] $modules = undef,
){
  apt::ppa { 'ppa:ondrej/php': }

  $versions.each |$cur_version| {
    @::profile::server::phpfpm::instance{ $cur_version: }
  }

  $modules.each |$cur_module, $cur_module_versions| {
    $cur_module_versions.each |$cur_module_version| {
      if $cur_module_version == '*' {
        $versions.each |$version| {
          @::profile::server::phpfpm::module{ "${version}-${cur_module}": }
        }
      } else {
        @::profile::server::phpfpm::module{ "${cur_module_version}-${cur_module}": }
      }
    }
  }
}
