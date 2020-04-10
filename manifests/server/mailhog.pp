class profile::server::mailhog {
  include ::stdlib

  exec { 'install_mailhog':
    command     => '/usr/bin/go get -u github.com/mailhog/MailHog/...',
    environment => ['GOPATH=/opt/go', 'GOCACHE=/opt/go/cache'],
    creates     => '/opt/go/src/github.com/mailhog/MailHog/',
    logoutput   => true,
    require     => [ Package['golang-go'] ],
  }

  systemd::unit_file { 'mailhog.service':
    source  => 'puppet:///modules/profile/mailhog/mailhog.service',
    enable  => true,
    active  => true,
    require => [Exec['install_mailhog']],
  }
}
