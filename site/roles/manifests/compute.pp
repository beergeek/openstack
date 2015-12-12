class roles::compute {

  class { 'profiles::base': }
  ->
  class { 'profiles::openstack_common': }
  ->
  class { 'profiles::compute': }
}
