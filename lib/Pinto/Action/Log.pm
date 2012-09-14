# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::Types::Moose qw(Bool Int Undef);

use Pinto::Types qw(StackName StackDefault);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault,
    default   => undef,
    coerce    => 1,
);


has revision => (
    is        => 'ro',
    isa       => Int | Undef,
    default   => undef,
);


has detailed => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    my $wanted_revision = $self->revision;
    my @revisions = defined $wanted_revision ? $stack->revision(number => $wanted_revision)
                                             : $stack->revisions; # plural!

    $self->fatal("No such revision $wanted_revision on stack $stack")
      if (!@revisions && defined $wanted_revision);

    my $format = "%k\@%b | %j | %u\n\n%g\n\n";
    for my $revision (reverse @revisions) {
        $self->say('-' x 79);
        $self->say($revision->to_string($format));
        $self->say(join "\n", $revision->registration_histories) if $self->detailed;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
