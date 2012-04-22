# ABSTRACT: Report the history of a stack

package Pinto::Action::Stack::Log;

use Moose;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends 'Pinto::Action';

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Stack::Log );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $revision_rs = $self->repos->get_revision_history(stack => $self->stack);
    while (my $revision = $revision_rs->next) {
        print { $self->out } $revision->message;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
