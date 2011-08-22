package Pinto::Exception::IO;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::IO' => { isa   => 'Pinto::Exception',
                                  alias => 'throw_io' },
);

use Readonly;
Readonly our @EXPORT_OK => qw(throw_io);

#-----------------------------------------------------------------------------

1;

__END__
