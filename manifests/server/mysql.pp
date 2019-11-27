class profile::server::mysql {
  $override_options = {
    'mysqld' => {
      'bind-address' => '0.0.0.0',
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
