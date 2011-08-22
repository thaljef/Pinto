package Pinto::Exception::Args;

# ABSTRACT: Exception classes used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::Args' => { isa   => 'Pinto::Exception',
                                    alias => 'throw_args' },
);

use Readonly;
Readonly our @EXPORT_OK => qw(throw_args);

#-----------------------------------------------------------------------------

1;

__END__
