class profiles::compute {

  require profiles::base
  package { 'centos-release-openstack-liberty':
    ensure => present,
  }

}
