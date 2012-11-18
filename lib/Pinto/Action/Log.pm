# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::Types::Moose qw(Bool Int Undef);

use Pinto::Util qw(trim);
use Pinto::Types qw(StackName StackDefault);
use Pinto::Exception qw(throw);

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

    my $stack = $self->repo->get_stack($self->stack);

    my $revnum = $self->revision;
    my @revisions = $stack->revision(number => $revnum);

    throw "No such revision $revnum on stack $stack"
      if !@revisions && defined $revnum;

    my $format = "%k\@%b | %j | %u\n\n%g";
    for my $revision (reverse @revisions) {
        $self->say('-' x 79);
        $self->say( trim( $revision->to_string($format) ) . "\n" );

        if ($self->detailed) {
            my @details = $revision->registration_changes;
            $self->say($_) for (@details ? @details : 'No details available')
        }
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
