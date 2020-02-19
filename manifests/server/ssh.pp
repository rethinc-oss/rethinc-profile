# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include profile::server::ssh
class profile::server::ssh (
  Integer $listen_port,
  Boolean $password_authentication,
  String $allowed_group,
  Boolean $sftp_only_enabled,
  Optional[String] $sftp_only_group = undef,
  Optional[String] $sftp_only_chroot = undef,
){
  if ($password_authentication) {
    $opt_password_auth = 'yes'
    $opt_auth_methods = 'publickey password'
  } else {
    $opt_password_auth = 'no'
    $opt_auth_methods = 'publickey'
  }

  if ($sftp_only_enabled) {
    unless !empty($sftp_only_group) { fail('expects a value for parameter \'sftp_only_group\'') }
    unless !empty($sftp_only_chroot) { fail('expects a value for parameter \'sftp_only_chroot\'') }
    $sftp_access = {
      "Match Group ${sftp_only_group}" => {
        'ChrootDirectory'    => $sftp_only_chroot,
        'ForceCommand'       => 'internal-sftp -f AUTHPRIV -l INFO -u 0027 -d %u',
        'AllowTcpForwarding' => 'no',
      }
    }
    $opt_allowed_groups = "${allowed_group} ${sftp_only_group}"
  } else {
    $sftp_access = {}
    $opt_allowed_groups = $allowed_group
  }

  $sshd_options = {
    'HostKey'                         => ['/etc/ssh/ssh_host_ed25519_key', '/etc/ssh/ssh_host_rsa_key', '/etc/ssh/ssh_host_ecdsa_key'],
    'Port'                            => $listen_port,
    'PasswordAuthentication'          => $opt_password_auth,
    'PermitRootLogin'                 => 'no',
    'KexAlgorithms'                   => 'curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256',
    'Ciphers'                         => 'chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr',
    'MACs'                            => 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512,hmac-sha2-256,umac-128@openssh.com',
    'AuthenticationMethods'           => $opt_auth_methods,
    'LogLevel'                        => 'VERBOSE',
    'PubkeyAuthentication'            => 'yes',
    'ChallengeResponseAuthentication' => 'no',
    'X11Forwarding'                   => 'no',
    'UsePAM'                          => 'yes',
    'Subsystem'                       => 'sftp /usr/lib/openssh/sftp-server -f AUTHPRIV -l INFO -d %d',
    'AllowGroups'                     => $opt_allowed_groups,
  }

  class { '::ssh::server':
    storeconfigs_enabled => false,
    options              => merge($sshd_options, $sftp_access),
  }

#File: /etc/ssh/moduli
}
