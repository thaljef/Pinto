# ABSTRACT: Show the difference between two stacks

package Pinto::Action::Diff;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Difference;
use Pinto::Constants qw(:color);
use Pinto::Types qw(StackName StackDefault StackObject RevisionID);
use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has left => (
    is      => 'ro',
    isa     => StackName | StackDefault | StackObject | RevisionID,
    default => undef,
);

has right => (
    is       => 'ro',
    isa      => StackName | StackObject | RevisionID,
    required => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $error_message = qq{"%s" does not match any stack or revision};

    my $left  =  $self->repo->get_stack( $self->left, (nocroak => 1) )
        || $self->repo->get_revision( $self->left )
        || throw sprintf $error_message, $self->left;

    my $right = $self->repo->get_stack( $self->right, (nocroak => 1) )
        || $self->repo->get_revision( $self->right )
        || throw sprintf $error_message, $self->right;
    
    my $diff = Pinto::Difference->new( left => $left, right => $right );

    if ($diff->is_different) {
        $self->show( "--- $left",  {color => $PINTO_COLOR_1});
        $self->show( "+++ $right", {color => $PINTO_COLOR_1});
    };

    for my $entry ( $diff->diffs ) {
        my $op     = $entry->op;
        my $reg    = $entry->registration;
        my $color  = $op eq '+' ? $PINTO_COLOR_0 : $PINTO_COLOR_2;
        my $string = $op . $reg->to_string('[%F] %-40p %12v %a/%f');
        $self->show( $string, { color => $color } );
    }

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
