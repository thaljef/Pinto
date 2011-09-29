package Pinto::Action::List;

# ABSTRACT: An abstract action for listing packages in a repository

use Moose;

use Carp qw(croak);

use MooseX::Types::Moose qw(Bool Str);
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


has format => (
    is      => 'ro',
    isa     => Str,
    default => '',
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
    my $format = $self->format();
    while( my $package = $rs->next() ) {
        print { $self->out() } $package->to_formatted_string($format);
    }

    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
