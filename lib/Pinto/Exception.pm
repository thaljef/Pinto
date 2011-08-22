package Pinto::Exception;

# ABSTRACT: Base class for Pinto exceptions

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class ( 'Pinto::Exception' => {isa  => 'Exception::Class::Base'} );

use base 'Exporter';

#-----------------------------------------------------------------------------

1;

__END__
