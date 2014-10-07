# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Difference;
use Pinto::RevisionWalker;
use Pinto::Constants qw(:color);
use Pinto::Types qw(StackName StackDefault DiffStyle);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault,
    default => undef,
);

has with_diffs => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

has diff_style => (
    is        => 'ro',
    isa       => DiffStyle,
    predicate => 'has_diff_style',
);


#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack( $self->stack );
    my $walker = Pinto::RevisionWalker->new( start => $stack->head );

    while ( my $revision = $walker->next ) {

        my $revid = $revision->to_string("revision %I");
        $self->show( $revid, { color => $PINTO_PALETTE_COLOR_1 } );

        my $rest = $revision->to_string("Date: %u\nUser: %j\n\n%{4}G\n");
        $self->show($rest);

        if ($self->with_diffs) {
            my $parent = ($revision->parents)[0];
            local $ENV{PINTO_DIFF_STYLE} = $self->diff_style if $self->has_diff_style;
            my $diff = Pinto::Difference->new(left => $parent, right => $revision);
            $self->show($diff);
        }
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
