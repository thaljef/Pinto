# ABSTRACT: Show the difference between stacks or revisions

package Pinto::Action::Diff;

use Moose;
use MooseX::Aliases;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Bool);

use Pinto::Difference;
use Pinto::Constants qw(:color :diff);
use Pinto::Types qw(StackName StackDefault StackObject RevisionID DiffStyle);
use Pinto::Util qw(throw default_diff_style);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has left => (
    is      => 'ro',
    isa     => StackName | StackObject | StackDefault | RevisionID,
    default => undef,
);

has right => (
    is       => 'ro',
    isa      => StackName | StackObject | RevisionID,
    required => 1,
);

has style => (
    is       => 'ro',
    isa      => DiffStyle,
    alias    => 'diff_style',
    default  => \&default_diff_style,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $error_message = qq{"%s" does not match any stack or revision};

    my $left =
           $self->repo->get_stack_maybe( $self->left )
        || $self->repo->get_revision_maybe( $self->left )
        || throw sprintf $error_message, $self->left;

    my $right =
           $self->repo->get_stack_maybe( $self->right )
        || $self->repo->get_revision_maybe( $self->right )
        || throw sprintf $error_message, $self->right;

    my $diff = Pinto::Difference->new( left  => $left,
                                       right => $right,
                                       style => $self->style );

    # TODO: Extract the colorizing & formatting code into a separate
    # class that can be reused.  Maybe subclassed for HTML and text.

    if ( $diff->is_different ) {
        $self->show( "--- $left",  { color => $PINTO_PALETTE_COLOR_1 } );
        $self->show( "+++ $right", { color => $PINTO_PALETTE_COLOR_1 } );
    }

    my $format = $self->style eq $PINTO_DIFF_STYLE_DETAILED
        ? '%o[%F] %-40p %12v %a/%f'
        : '%o[%F] %a/%f';

    for my $entry ( $diff->entries ) {
        my $color  = $entry->is_addition ? $PINTO_PALETTE_COLOR_0 : $PINTO_PALETTE_COLOR_2;
        my $string = $entry->to_string($format);
        $self->show( $string, { color => $color } );
    }

    $self->notice('No difference') if not $diff->is_different;

    return $self->result;
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
