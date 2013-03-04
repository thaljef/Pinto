# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::RevisionWalker;
use Pinto::Types qw(StackName StackDefault);


#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
);


has format => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_format',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack  = $self->repo->get_stack($self->stack);
    my $walker = Pinto::RevisionWalker->new(start => $stack->head);

    while (my $revision = $walker->next) {
        $self->say( $revision->to_string($self->format) ); 
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _build_format {
    my ($self) = @_;

    my $c = $self->color_2;
    my $r = $self->color_0;

    return <<"END_FORMAT";
${c}revision %I${r}
Date: %u
User: %j 

%{4}G
END_FORMAT

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
