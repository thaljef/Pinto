
# Puppet pinto manifest
# This manifest was slightly adapted from working 
# code in my own environment, but has not been 
# explicitly tested itself.  Small changes may be needed.

class pinto {

    file { [    '/opt',
                '/opt/local',
                '/root/lib',
                '/root/lib/sh' ],
        ensure => 'directory',
    }

    group { 'pinto':
        gid => 121,
     ensure => present,
     system => true,
    }

    user { 'pinto':
           comment => 'pintod-perl-repo-curator',
              home => '/opt/local/pinto',
             shell => '/bin/bash',
               uid => '121',
               gid => '121',
          password => '*', 
        managehome => 'true',
            ensure => 'present',
            system => true,
           require => [ File['/opt/local'], Group['pinto'] ],
    }

    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    file { "/etc/pinto":
        ensure => "directory",
         owner => 'pinto',
         group => 'pinto',
          mode => '754',
    }

    file { '/opt/local/pinto':
        ensure => "directory",
	     owner => 'pinto',
	     group => 'pinto',
          mode => '755',
       require => [ File['/opt/local'] ],
    }

    file { '/opt/local/pinto/.ssh':
        ensure => "directory",
	     owner => 'pinto',
	     group => 'pinto',
          mode => '700',
       require => [ File['/opt/local/pinto'] ],
    }

    file { '/root/lib/sh/pinto_install.sh':
          mode => 744,
         owner => 'root',
         group => 'root',
       replace => true,
       ensure  => present,
        source => 'puppet:///modules/pinto/root/lib/sh/pinto_install.sh',
       require => [ File['/opt/local/pinto'] ],
    }

    exec { 'install-pinto':
        timeout => 1200,
        command => '/root/lib/sh/pinto_install.sh',
	    creates => '/opt/local/pinto/version',
        require => [ File['/opt/local/pinto'] ],
    }

    exec { 'create-pinto-version-file':
	command => '/opt/local/pinto/bin/pinto --version > /opt/local/pinto/version',
	require => [ Exec['install-pinto'] ],
    }

    if $fqdn =~ /^pinto-repo.*/ {

        file { '/etc/pinto/htpasswd':
            ensure => 'directory',
             owner => 'root',
             group => 'pinto',
              mode => '640',
            source => 'puppet:///modules/pinto/etc/pinto/htpasswd.starter',
           require => [ File['/etc/pinto'] ],
        }

        file { '/var/pinto':
              mode => 744,
             owner => 'pinto',
             group => 'pinto',
            ensure => 'directory',
        }

        file { '/etc/init.d/pintod':
              mode => 754,
             owner => 'root',
             group => 'pinto',
           replace => true,
            ensure => present,
            source => "puppet:///modules/pinto/etc/init.d/pintod.$osfamily",
           require => [ File['/opt/local/pinto'], File['/var/pinto'] ],
        }

        exec { 'pinto-init':
               user => 'pinto',
            command => '/opt/local/pinto/bin/pinto -r /var/pinto init', 
            require => [ File['/var/pinto'], Exec['install-pinto'] ],
            creates => '/var/pinto/stacks/master/authors/01mailrc.txt.gz',
        }
    
        file { "/var/run/pinto":
               owner => 'pinto',
               group => 'pinto',
                mode => '754',
              ensure => "directory",
        }

        exec { '/etc/init.d/pintod':
               user => 'pinto',
            creates => '/var/run/puppet/pintod.starman.pid',
            command => '/etc/init.d/pintod start',
            require => [ Exec['pinto-init'], File['/etc/init.d/pintod'] ],
        }

    }

}

