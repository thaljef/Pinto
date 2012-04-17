# ABSTRACT: Loosen a package that has been pinned

package Pinto::Action::Unpin;

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Unpin );

#------------------------------------------------------------------------------

has stack   => (
    is      => 'ro',
    isa     => StackName,
    default => 'default',
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    # TODO: Should this check also be placed in the PackageStack too?
    # I think we also want it here so we can do it as early as possible

    $self->fatal('The default stack cannot have pins anyway')
        if $self->stack() eq 'default';

    return $self;
}

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $stack_name = $self->stack();
    my $stack = $self->repos->get_stack(name => $stack_name);

    if (not $stack) {
        $self->warning("Stack $stack_name does not exist");
        return;
    }

    return $self->_do_unpin($stack);
}

#------------------------------------------------------------------------------

sub _do_unpin {
    my ($self, $stack) = @_;

    my $pkg_name = $self->package();
    my $attrs    = { prefetch => 'package' };
    my $where    = { 'package.name' => $pkg_name, stack => $stack->id() };
    my $pkg_stk  = $self->repos->db->select_package_stacks($where, $attrs)->single();

    if (not $pkg_stk) {
        $self->warning("Package $pkg_name is not in stack $stack");
        return;
    }

    if (not $pkg_stk->is_pinned()) {
        $self->whine("Package $pkg_stk is not pinned");
        return;
    }

    $self->info("Unpinning package $pkg_stk");
    $pkg_stk->pin(undef);
    $pkg_stk->update();

    return 1;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
