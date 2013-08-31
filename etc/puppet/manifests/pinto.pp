
# Puppet pinto manifest
# Copyright 2013 Hugh Esco <hesco@campaignfoundations.com>

class pinto {
    # require postfix 

    Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

    user { "pinto":
           comment => "pintod-perl-repo-curator",
              home => "/opt/local/pinto",
             shell => "/bin/false",
            ensure => 'present',
               uid => 121,
               gid => 121,
            system => true,
        managehome => 'true',
          password => '*',
            groups => ['pinto'] 
    }

    group { "pinto":
        gid => 121
    }

    file { "/opt":
        ensure => "directory",
    }

    file { "/opt/local":
        ensure => "directory",
    }

    file { "/opt/local/pinto":
        ensure => "directory",
	 owner => 'pinto',
	 group => 'pinto',
	  mode => '02755',
       require => [ User["pinto"] ],
    }

    file { "/root/lib":
        ensure => "directory",
    }

    file { "/root/lib/sh":
        ensure => "directory",
    }

    file { "/root/lib/sh/pinto_install.sh":
          mode => 755,
         owner => "root",
         group => "root",
       replace => true,
       ensure  => present,
        source => "puppet:///modules/pinto/root/lib/sh/pinto_install.sh",
       require => [ User["pinto"] ],
    }

    exec { '/root/lib/sh/pinto_install.sh':
        timeout => 600,
        command => '/root/lib/sh/pinto_install.sh',
        require => [ File['/root/lib/sh/pinto_install.sh'] ],
    }

}

