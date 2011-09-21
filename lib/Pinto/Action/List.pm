package Pinto::Action::List;

# ABSTRACT: An abstract action for listing packages in a repository

use Moose;

use Carp qw(croak);

use MooseX::Types::Moose qw(Bool);
use Pinto::Types 0.017 qw(IO);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------

has out => (
    is      => 'ro',
    isa     => IO,
    coerce  => 1,
    default => sub { [fileno(STDOUT), '>'] },
);


has indexed => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

#------------------------------------------------------------------------------

sub packages { croak 'Abstract method!' }

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $rs = $self->packages();
    while( my $package = $rs->next() ) {
        print { $self->out() } $package->to_index_string();
    }

    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
