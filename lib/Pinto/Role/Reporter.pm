# ABSTRACT: Something that reports about the repository

package Pinto::Role::Reporter;

use Moose::Role;

use Pinto::Types qw(Io);

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has out => (
    is      => 'ro',
    isa     => Io,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);

#-----------------------------------------------------------------------------

1;

__END__
