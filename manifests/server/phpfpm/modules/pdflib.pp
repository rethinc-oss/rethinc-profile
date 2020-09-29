define profile::server::phpfpm::modules::pdflib(
  String $php_version = undef,
){
  $extension_infos = {
    '7.2' => {
      extension_dir => '/usr/lib/php/20170718',
      source_dir => 'PDFlib-9.2.0p6-Linux-x86_64-php/bind/php/php-720-nts'
    },
    '7.3' => {
      extension_dir => '/usr/lib/php/20180731',
      source_dir => 'PDFlib-9.2.0p6-Linux-x86_64-php/bind/php/php-730-nts'
    },
    '7.4' => {
      extension_dir => '/usr/lib/php/20190902',
      source_dir => 'PDFlib-9.2.0p6-Linux-x86_64-php/bind/php/php-740-nts'
    }
  }

  remote_file { 'download_dist_archive':
    ensure => present,
    path   => '/tmp/pdflib-9.2.0.tar',
    source => 'https://www.pdflib.com/binaries/PDFlib/920/PDFlib-9.2.0p6-Linux-x86_64-php.tar.gz',
  }

  exec { 'extract_dist_archive':
    cwd     => '/tmp',
    command => '/bin/tar xvf /tmp/pdflib-9.2.0.tar',
    require => Remote_file['download_dist_archive'],
  }

  file { 'install_module_dso':
    path    => "${extension_infos[$php_version]['extension_dir']}/php_pdflib.so",
    mode    => '0644',
    source  => "/tmp/${extension_infos[$php_version]['source_dir']}/php_pdflib.so",
    require => Exec['extract_dist_archive'],
  }

  file { 'install_module_config':
    path    => "/etc/php/${php_version}/mods-available/pdflib.ini",
    mode    => '0644',
    source  => 'puppet:///modules/profile/phpfpm/pdflib.ini',
    require => File['install_module_dso'],
  }

  file { 'link_cli':
    ensure  => link,
    path    => "/etc/php/${php_version}/cli/conf.d/30-pdflib.ini",
    target  => "/etc/php/${php_version}/mods-available/pdflib.ini",
    require => File['install_module_config'],
  }

  file { 'link_fpm':
    ensure  => link,
    path    => "/etc/php/${php_version}/fpm/conf.d/30-pdflib.ini",
    target  => "/etc/php/${php_version}/mods-available/pdflib.ini",
    require => File['install_module_config'],
  }
}
