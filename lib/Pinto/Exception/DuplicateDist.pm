package Pinto::Exception::DuplicateDist;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::DuplicateDist' => { isa   => 'Pinto::Exception' },
);

#-----------------------------------------------------------------------------

1;

__END__
