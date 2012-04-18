# ABSTRACT: Force a package into the index

package Pinto::Action::Pin;

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Pin );

#------------------------------------------------------------------------------

has reason   => (
    is        => 'ro',
    isa       => Str,
    default   => 'no reason was given',
);


has stack   => (
    is        => 'ro',
    isa       => StackName,
    required  => 1,
    coerce    => 1,
);

#------------------------------------------------------------------------------
# Construction

sub BUILD {
    my ($self) = @_;

    # TODO: Should this check also be placed in the PackageStack too?
    # I think we also want it here so we can do it as early as possible

    $self->fatal('You cannot place pins on the default stack')
        if $self->stack eq 'default';

    return $self;
}

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $stack_name = $self->stack;

    if (not $self->repos->get_stack( name => $stack_name )) {
        $self->error("Stack $stack_name does not exist"); # Make fatal?
        return $self->result->failed;
    }

    # TODO: something like $stack->get_package( package => $self->package );

    my $pkg_stk = $self->repos->get_stack_member( package => $self->package,
                                                  stack   => $self->stack );

    if (not $pkg_stk) {
        my ($pkg) = $self->package;
        $self->error("Package $pkg is not in stack $stack_name"); # Make fatal?
        return $self->result->failed;
    }


    if ( $pkg_stk->is_pinned ) {
        $self->warning(sprintf "Package $pkg_stk is already pinned: %s", $pkg_stk->reason);
        return $self->result;
    }

    # TODO: Decide how to handle pinning of developer distributions
    # $self->whine("This repository does not permit pinning developer packages")
    #     and return 0 if $pkg->distribution->is_devel() and not $self->config->devel();

    $self->info( sprintf 'Pinning package %s on stack %s',
                 $pkg_stk->package, $pkg_stk->stack );

    # TODO: Should we just use the message as the reason (or vice-versa) ?

    my $pin = $self->repos->db->create_pin( { reason => $self->reason } );
    $pkg_stk->pin($pin);
    $pkg_stk->update;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
