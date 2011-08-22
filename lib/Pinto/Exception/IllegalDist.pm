package Pinto::Exception::IllegalDist;

# ABSTRACT: Exception class used by Pinto

use strict;
use warnings;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

use Exception::Class (

      'Pinto::Exception::IllegalDist' => { isa   => 'Pinto::Exception' },
);

#-----------------------------------------------------------------------------

1;

__END__
