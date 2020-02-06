# https://github.com/kogitoapp/puppet-minio
class profile::server::minio (
  $server_version = 'RELEASE.2020-01-25T02-50-51Z',
  $server_checksum = '453087d2a1cde0f5484854a51411246ce324386d16656a58b816394ad73bc237',
  $client_version = 'RELEASE.2020-01-25T03-02-19Z',
  $client_checksum = '792d5365a5fed9ffc14b78a4fbd4ab42bd5a6ff60a58e486075841b4e83975ab',
  $checksum_type = 'sha256',
  $listen_ip = '',
  $listen_port = '10001',
){
  $defaults_directory = '/etc/default'
  $installation_directory = '/opt/minio'
  $storage_root = '/var/minio'
  $log_directory = '/var/log/minio'
  $group = 'minio'
  $user = 'minio'
  $homedir = '/home/minio'
  $base_url_server = 'https://dl.minio.io/server/minio/release'
  $base_url_client = 'https://dl.minio.io/client/mc/release'
  $environment_template = 'profile/minio/default.erb'
  $service_template = 'profile/minio/systemd.erb'
  $service_path = '/etc/systemd/system/minio.service'
  $service_provider = 'systemd'
  $service_mode = '0644'

  ## USER
  group { $group:
    ensure => present,
    system => true,
  }

  user { $user:
    ensure     => present,
    gid        => $group,
    home       => $homedir,
    managehome => true,
    system     => true,
    require    => Group[$group],
  }

  ## PROGRAM
  file { $storage_root:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    notify => Exec["permissions:${storage_root}"],
  }

  -> file { $installation_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    notify => Exec["permissions:${installation_directory}"],
  }

  -> file { $log_directory:
    ensure => 'directory',
    owner  => $user,
    group  => $group,
    notify => Exec["permissions:${log_directory}"],
  }

  $kernel_down=downcase($::kernel)

  case $::architecture {
    /(x86_64)/: {
      $arch = 'amd64'
    }
    /(x86)/: {
      $arch = '386'
    }
    default: {
      $arch = $::architecture
    }
  }

  $source_url_server="${base_url_server}/${kernel_down}-${arch}/archive/minio.${server_version}"
  $source_url_client="${base_url_client}/${kernel_down}-${arch}/archive/mc.${client_version}"

  remote_file { 'minio':
    ensure        => present,
    path          => "${installation_directory}/minio",
    source        => $source_url_server,
    checksum      => $server_checksum,
    checksum_type => $checksum_type,
    notify        => [
      Exec["permissions:${$installation_directory}/minio"],
      Service['minio']
    ],
  }

  remote_file { 'mcc':
    ensure        => present,
    path          => "${installation_directory}/mcc",
    source        => $source_url_client,
    checksum      => $client_checksum,
    checksum_type => $checksum_type,
    notify        => [
      Exec["permissions:${$installation_directory}/mcc"],
    ],
  }

  exec { "permissions:${installation_directory}":
    command     => "chown -Rf ${user}:${group} ${installation_directory}",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  exec { "permissions:${$installation_directory}/minio":
    command     => "chmod +x ${$installation_directory}/minio",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  exec { "permissions:${$installation_directory}/mcc":
    command     => "chmod +x ${$installation_directory}/mcc",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  exec { "permissions:${storage_root}":
    command     => "chown -Rf ${user}:${group} ${storage_root}",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  exec { "permissions:${log_directory}":
    command     => "chown -Rf ${user}:${group} ${log_directory}",
    path        => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    refreshonly => true,
  }

  file { "service:${defaults_directory}/minio":
    path    => "${defaults_directory}/minio",
    content => template($environment_template),
    mode    => $service_mode,
  }

  file { "service:${service_path}":
    path    => $service_path,
    content => template($service_template),
    mode    => $service_mode,
  }


  ## SERVICE
  service { 'minio':
    ensure     => 'running',
    enable     => true,
    hasstatus  => false,
    hasrestart => false,
    provider   => $service_provider,
    subscribe  => Remote_File['minio'],
  }

  -> exec { 'setup:add_local_instance_for_sysop':
    command => '/opt/minio/mcc config host add local http://127.0.0.1:10001 minioadmin minioadmin --api S3v4',
    path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    user    => 'sysop',
    require => [Remote_file['mcc']],
  }
  -> exec { 'setup:add_local_instance_for_root':
    command => '/opt/minio/mcc config host add local http://127.0.0.1:10001 minioadmin minioadmin --api S3v4',
    path    => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
    require => [Remote_file['mcc']],
  }
}
