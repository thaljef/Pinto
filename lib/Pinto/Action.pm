# ABSTRACT: Base class for all Actions

package Pinto::Action;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Result;
use Pinto::Types qw(Io);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Loggable );

#------------------------------------------------------------------------------


has repos => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has username => (
    is       => 'ro',
    isa      => Str,
    default  => sub { $ENV{USER} },
);


has out => (
    is      => 'ro',
    isa     => Io,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);


has result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
