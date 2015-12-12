class profiles::openstack_common {

  if $::os['family'] != 'RedHat' and $::os['release']['major'] != '7' {
    fail('This module is for RHEL7 only')
  }
  require profiles::base
  package { 'centos-release-openstack-liberty':
    ensure => present,
  }
  package { ['openstack-selinux']:
    ensure => present, 
    require => Package['centos-release-openstack-liberty'],
  }
}
