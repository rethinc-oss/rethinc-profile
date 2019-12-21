class profile::server::golang {
  include ::stdlib

  apt::ppa { 'ppa:longsleep/golang-backports': }

  package{ 'golang-go':
    ensure  => present,
    require => [ Class['apt::update'], Apt::Ppa['ppa:longsleep/golang-backports'] ],
  }
}
