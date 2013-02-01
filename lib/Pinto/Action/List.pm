# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::Types::Moose qw(HashRef Str Bool Undef);

use Pinto::Types qw(AuthorID StackName StackAll StackDefault StackObject);
use Pinto::Util qw(is_stack_all);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has pinned => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


has author => (
    is     => 'ro',
    isa    => AuthorID,
);


has packages => (
    is     => 'ro',
    isa    => Str,
);


has distributions => (
    is     => 'ro',
    isa    => Str,
);


has format => (
    is        => 'ro',
    isa       => Str,
    default   => '%-32p  %12v  %A/%f  %i',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $auth    = $self->author;
    my $auth_rx = $auth ? qr/$auth/i : undef;

    my $pkg    = $self->packages;
    my $pkg_rx = $pkg ? qr/$pkg/i : undef;

    my $dist    = $self->distributions;
    my $dist_rx = $dist ? qr/$dist/i : undef;

    my $pinned = $self->pinned;

    my $stack = $self->repo->get_stack($self->stack);

    for my $entry ( @{ $stack->registry->entries } ) {
        next if $auth_rx  && $entry->author       !~ $auth_rx;
        next if $pkg_rx   && $entry->package      !~ $pkg_rx;
        next if $dist_rx  && $entry->distribution !~ $dist_rx;
        next if $pinned   && not $entry->is_pinned; 
        $self->say($entry->to_string($self->format));
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
