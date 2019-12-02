class profile::server::mysql {
  $override_options = {
    'mysqld' => {
      'bind-address' => '0.0.0.0',
      'sql-mode' => 'ONLY_FULL_GROUP_BY,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION',
    }
  }

  class { '::mysql::server':
    root_password           => 'root',
    remove_default_accounts => false,
    restart                 => true,
    override_options        => $override_options,
  }

  mysql_user { "root@%":
    ensure        => present,
    password_hash => mysql_password('root'),
  }

  mysql_grant { 'root@%/*.*':
    ensure     => 'present',
    options    => ['GRANT'],
    privileges => ['ALL'],
    table      => '*.*',
    user       => 'root@%',
  }

#  mysql_user { "root@_gateway":
#    ensure        => present,
#    password_hash => mysql_password('root'),
#  }
#
#  mysql_grant { 'root@_gateway/*.*':
#    ensure     => 'present',
#    options    => ['GRANT'],
#    privileges => ['ALL'],
#    table      => '*.*',
#    user       => 'root@_gateway',
#  }
}
