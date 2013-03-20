# ABSTRACT: Show the difference between two stacks

package Pinto::Action::Diff;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Difference;
use Pinto::Constants qw(:color);
use Pinto::Types qw(StackName StackDefault StackObject RevisionID);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has left_stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    default  => undef,
);


has right_stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $left  = $self->repo->get_stack($self->left_stack);
    my $right = $self->repo->get_stack($self->right_stack);

    my $diff  = Pinto::Difference->new(left => $left, right => $right);

    my $cb = sub {
        my ($op, $reg) = @_;
        my $color  = $op eq '+' ? $PINTO_COLOR_0 : $PINTO_COLOR_2;
        my $string = $op . $reg->to_string('[%F] %-40p %12v %a/%f');
        $self->show($string, {color => $color});
    };

    $diff->foreach($cb);

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
