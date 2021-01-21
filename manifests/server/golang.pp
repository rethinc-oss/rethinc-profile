class profile::server::golang {
  include ::stdlib

  @apt::ppa { 'ppa:longsleep/golang-backports': }
  ensure_packages(['golang-go'])
}
