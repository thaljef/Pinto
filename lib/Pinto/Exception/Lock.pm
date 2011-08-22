package Pinto::Exception::Lock;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::Lock' => { isa   => 'Pinto::Exception',
                                    alias => 'throw_lock' },
);

use Readonly;
Readonly our @EXPORT_OK => qw(throw_lock);

#-----------------------------------------------------------------------------

1;

__END__
