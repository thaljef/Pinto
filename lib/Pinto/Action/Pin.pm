package Pinto::Action::Pin;

# ABSTRACT: Force a package into the index

use Moose;
use MooseX::Types::Moose qw(Str);

use Pinto::Types qw(Vers StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has package => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has version => (
    is        => 'ro',
    isa       => Vers,
    predicate => 'has_version',
    coerce    => 1,
);

has stack   => (
    is        => 'ro',
    isa       => StackName,
    default   => 'default',
    coerce    => 1,
);


has reason   => (
    is        => 'ro',
    isa       => Str,
    default   => 'no reason was given',
);

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $pkg_stk = $self->_get_package_stack() or return 0;

    $self->whine(sprintf "Package $pkg_stk is already pinned: %s", $pkg_stk->reason())
        and return 0 if $pkg_stk->is_pinned();

    # TODO: Decide how to handle pinning of developer distributions
    # $self->whine("This repository does not permit pinning developer packages")
    #     and return 0 if $pkg->distribution->is_devel() and not $self->config->devel();

    $self->_do_pin($pkg_stk);

    return 1;
}

#------------------------------------------------------------------------------

sub _get_package_stack {
    my ($self) = @_;

    my $where = { 'package.name' => $self->package(),
                  'stack.name'   => $self->stack() };
    my $attrs = { prefetch => [ qw(package stack) ] };

    my $pkg_stk = $self->repos->db->select_package_stack($where, $attrs)->single();

    if (not $pkg_stk) {
        my $pkg_vname = sprintf '%s-%s', $self->package(), $self->version();
        $self->whine( sprintf "Package $pkg_vname is not in stack %s", $self->stack() );
        return;
    }

    return $pkg_stk;
}

#------------------------------------------------------------------------------

sub _do_pin {
    my ($self, $pkg_stk) = @_;

    $self->info( sprintf 'Pinning package %s on stack %s',
                 $pkg_stk->package(), $pkg_stk->stack() );

    my $pin = $self->repos->db->create_pin( { reason => $self->reason() } );
    $pkg_stk->pin($pin);
    $pkg_stk->update();

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
