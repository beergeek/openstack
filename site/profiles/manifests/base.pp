class profiles::base {

  require epel
  package { ['ruby']:
    ensure => present,
  }
  class { 'ntp':
    servers => ['10.20.1.1'],
  }
}
