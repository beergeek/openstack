class profiles::controller {

  require profiles::base
  file { '/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-94':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/profiles/RPM-GPG-KEY-PGDG-94',
  }
  yumrepo { 'pgdg94':
    ensure   => 'present',
    baseurl  => 'http://yum.postgresql.org/9.4/redhat/rhel-$releasever-$basearch',
    descr    => 'PostgreSQL 9.4 $releasever - $basearch',
    enabled  => '1',
    gpgcheck => '1',
    gpgkey   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-94',
    require  => File['/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-94'],
  }
  class { '::mysql::server':
    override_options => {
      'mysqld'                 => {
        'bind-address'           => $::ipaddress_enp0s8,
        'default-storage-engine' => 'innodb',
        'innodb_file_per_table'  => '',
        'collation-server'       => 'utf8_general_ci',
        'init-connect'           => 'SET NAMES utf8',
        'character-set-server'   => 'utf8',
      }
    }
  }

  ['localhost'].each |$host| {
    mysql_user { "keystone@${host}":
      ensure        => present,
      password_hash => mysql_password('clownpants'),
    }
    mysql_grant { "keystone@${host}/keystone.*":
      ensure     => present,
      privileges => 'ALL',
      user       => "keystone@${host}",
      table      => 'keystone.*',
      require    => [Mysql_database['keystone'],Mysql_user["keystone@${host}"],],
    }
  }

  class { '::rabbitmq':
  }
  rabbitmq_user { 'openstack':
    password => 'openstack',
  }
  rabbitmq_user_permissions { 'openstack@/':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    require              => Class['::rabbitmq'],
  }

  class { 'keystone':
    verbose             => true,
    debug               => true,
    catalog_type        => 'sql',
    admin_token         => '14831655310a38764455',
    token_provider      => 'uuid',
    token_driver        => 'memcache',
    memcache_servers    => ['localhost:11211'],
    revoke_driver       => 'sql',
    database_connection => 'mysql://keystone:clownpants@controller.puppetlabs.vm/keystone',
  }

  class { 'keystone::db::mysql':
    password      => 'clownpants',
    allowed_hosts => '%',
  }

  #  class { 'apache':
  #    servername => 'controller',
  #  }
  #
  #  class { 'apache::mod::wsgi': }
  #
  #  #  apache::vhost { 'keystone_5000':
  #  #    docroot             => false,
  #  #    manage_docroot      => false,
  #  #    port                => '5000',
  #  #    wsgi_daemon_process => 'keystone-public',
  #  #    wsgi_daemon_process_options => {
  #  #      processes    => '5',
  #  #      threads      => '1',
  #  #      user         => 'keystone',
  #  #      group        => 'keystone',
  #  #      display-name => '%{GROUP}',
  #  #    },
  #  #    wsgi_process_group      => 'keystone-public',
  #  #    wsgi_script_aliases     => {'/' => '/usr/bin/keystone-wsgi-public'},
  #  #    wsgi_pass_authorization => 'On',
  #  #    custom_fragment         => '
  #  #    WSGIApplicationGroup %{GLOBAL}
  #  #    <Directory /usr/bin>
  #  #        <IfVersion >= 2.4>
  #  #            Require all granted
  #  #        </IfVersion>
  #  #        <IfVersion < 2.4>
  #  #            Order allow,deny
  #  #            Allow from all
  #  #        </IfVersion>
  #  #    </Directory>',
  #  #  }
  #
  #    apache::vhost { 'keystone_35357':
  #      servername          => 'controller',
  #      docroot             => false,
  #      manage_docroot      => false,
  #      port                => '35357',
  #      wsgi_daemon_process => 'keystone-admin',
  #      wsgi_daemon_process_options => {
  #        processes    => '5',
  #        threads      => '1',
  #        user         => 'keystone',
  #        group        => 'keystone',
  #        display-name => '%{GROUP}',
  #      },
  #      wsgi_process_group      => 'keystone-admin',
  #      wsgi_script_aliases     => {'/' => '/usr/bin/keystone-wsgi-admin'},
  #      wsgi_pass_authorization => 'On',
  #      custom_fragment         => '
  #      WSGIApplicationGroup %{GLOBAL}
  #      <Directory /usr/bin>
  #          <IfVersion >= 2.4>
  #              Require all granted
  #          </IfVersion>
  #          <IfVersion < 2.4>
  #              Order allow,deny
  #              Allow from all
  #          </IfVersion>
  #      </Directory>',
  #    }

    # Service
    keystone_service { 'keystone::identity':
      ensure      => present,
      description => 'OpenStack Identity',
    }

    # Endpoint
    keystone_endpoint { 'RegionOne/keystone::identity':
      ensure       => present,
      public_url   => 'http://controller:5000/v2.0',
      admin_url    => 'http://controller:35357/v2.0',
      internal_url => 'http://controller:5000/v2.0',
    }
}
