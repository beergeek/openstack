class roles::controller {

  class { 'profiles::base': }
  ->
  class { 'profiles::openstack_common': }
  ->
  class { 'profiles::controller': }
}
