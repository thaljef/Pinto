# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::RevisionWalker;
use Pinto::Constants qw(:color);
use Pinto::Types qw(StackName StackDefault);


#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
);


has format => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_format',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack  = $self->repo->get_stack($self->stack);
    my $walker = Pinto::RevisionWalker->new(start => $stack->head);

    while (my $revision = $walker->next) {

        my $revid = $revision->to_string("revision %I");
        $self->show($revid, {color => $PINTO_COLOR_1});

        my $rest = $revision->to_string("Date: %u\nUser: %j\n\n%{4}G\n");
        $self->show($rest);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
