package Pinto::Exception::Unauthorized;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::Unauthorized' => { isa   => 'Pinto::Exception' },
);

#-----------------------------------------------------------------------------

1;

__END__
