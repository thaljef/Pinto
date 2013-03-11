# ABSTRACT: Show the difference between two stacks or revisions

package Pinto::Action::Diff;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Difference;
use Pinto::Types qw(StackName StackDefault StackObject RevisionID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

#------------------------------------------------------------------------------

has left_stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    required => 1,
);


has right_stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $left_rev  = $self->repo->get_stack($self->left_stack)->head;
    my $right_rev = $self->repo->get_stack($self->right_stack)->head;

    my $diff = Pinto::Difference->new( left    => $left_rev, 
                                       right   => $right_rev,
                                       nocolor => $self->nocolor );

    $self->say($diff->to_string);

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
