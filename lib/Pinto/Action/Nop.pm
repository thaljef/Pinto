package Pinto::Action::Nop;

# ABSTRACT: A no-op action

use Moose;

use MooseX::Types::Moose qw(Int);

extends 'Pinto::Action';

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has sleep => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    if ( my $sleep = $self->sleep() ) {
        $self->debug("Process $$ sleeping for $sleep seconds");
        sleep $self->sleep();
    }

    return 0;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

=pod

=head1 DESCRIPTION

This action does nothing.  It can be used to get Pinto to initialize
the store and load the indexes without performing any real operations
on them.

=cut

1;

__END__
