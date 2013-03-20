# ABSTRACT: Base class for all Actions

package Pinto::Action;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use IO::Handle;

use Pinto::Result;
use Pinto::Exception;
use Pinto::Util qw(is_interactive);
use Pinto::Constants qw($PINTO_LOCK_TYPE_SHARED);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Plated );

#------------------------------------------------------------------------------


has repo  => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has result => (
    is       => 'ro',
    isa      => 'Pinto::Result',
    default  => sub { Pinto::Result->new },
    init_arg => undef,
    lazy     => 1,
);


has lock_type => (
    is        => 'ro',
    isa       => Str,
    default   => $PINTO_LOCK_TYPE_SHARED,
    init_arg  => undef,
);

#------------------------------------------------------------------------------

sub BUILD {}

#------------------------------------------------------------------------------

sub execute { throw 'Abstract method' }

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
