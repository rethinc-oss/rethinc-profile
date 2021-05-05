define profile::server::phpfpm::composer(
  String $target_path       = $title,
  String $owner             = undef,
  String $group             = $owner,
  String $mode              = '0770',
  Optional[String] $version = undef,
  $download_timeout         = '0',
){

  $source_url = $version ? {
    undef   => 'https://getcomposer.org/composer-stable.phar',
    default => "https://getcomposer.org/download/${version}/composer.phar"
  }

  $unless = $version ? {
    undef   => "/usr/bin/test -f ${target_path}",
    default => "/usr/bin/test -f ${target_path} && ${target_path} -V | /usr/bin/grep -q ${version}"
  }

  ensure_packages(['wget'])

  exec { "composer-install-${target_path}":
    command => "/usr/bin/wget --no-check-certificate -O ${target_path} ${source_url}",
    user    => $owner,
    unless  => $unless,
    timeout => $download_timeout,
    require => Package['wget'],
  }

  file { $target_path:
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => $mode,
    require => Exec["composer-install-${target_path}"],
  }
}
