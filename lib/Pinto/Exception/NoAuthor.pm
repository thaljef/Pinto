package Pinto::Exception::NoAuthor;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::NoAuthor' => { isa   => 'Pinto::Exception' },
);

#-----------------------------------------------------------------------------

1;

__END__
