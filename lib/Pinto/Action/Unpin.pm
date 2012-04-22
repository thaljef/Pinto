# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Unpin );

#------------------------------------------------------------------------------

has stack   => (
    is       => 'ro',
    isa      => StackName,
    coerce   => 1,
    required => 1,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    # TODO: Should this check also be placed in the PackageStack too?
    # I think we also want it here so we can do it as early as possible

    $self->fatal('The default stack cannot have pins anyway')
        if $self->stack eq 'default';

    return $self;
}

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    $self->repos->unpin( package => $self->package,
                         stack   => $self->stack );

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
