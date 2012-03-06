package Pinto::Action::Stack::Merge;

# ABSTRACT: An action to merge one stack into another

use Moose;

use Pinto::Types qw(StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attributes

has from_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);


has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------
# Methods

override execute => sub {
    my ($self) = @_;

    my $source_stack_name = $self->from_stack();
    my $source_stack = $self->repos->db->select_stacks( {name => $source_stack_name} )->single()
        or confess "Stack $source_stack_name does not exist";

    my $target_stack_name = $self->to_stack();
    my $target_stack = $self->repos->db->select_stacks( {name => $target_stack_name} )->single()
        or confess "Stack $target_stack_name does not exist";

    my $where = { stack => $source_stack->id() };
    my $package_stack_rs = $self->repos->db->select_package_stack( $where );

    $self->note("Merging stack $source_stack into stack $target_stack");

    while ( my $source_pkg_stk = $package_stack_rs->next() ) {

        $self->note("Merging package $source_pkg_stk into stack $target_stack");

        my $where = { 'package.name' => $source_pkg_stk->package->name(),
                      'stack'        => $target_stack->id() };

        my $attrs = { prefetch => 'package' };

        my $target_pkg_stk = $self->repos->db->select_package_stack($where, $attrs)->single();

        $self->_merge_pkg_stk( $source_pkg_stk, $target_pkg_stk, $target_stack );
    }

    return;
};

#------------------------------------------------------------------------------

sub _merge_pkg_stk {
    my ($self, $source, $target, $to_stack) = @_;

    # CASE 1:  The package does not exist in the target stack,
    # so we can go ahead and just add it there.

    if (not defined $target) {
         my $pkg = $source->package();
         $self->debug("Adding package $pkg to stack $to_stack");
         $source->copy( {stack => $to_stack} );
         return;
     }

    # CASE 2:  The exact same package is in both the source
    # and the target stacks, so we don't have to merge.  But
    # if the source is pinned, then we should also copy the
    # pin to the target.

    if ($target == $source) {
        $self->debug("$source and $target are the same");
        if ($source->is_pinned) {
            $self->debug("Adding pin to $target");
            $target->pin( $source->pin() );
            $target->update();
            return;
        }
        return;
    }

    # CASE 3:  The package in the target stack is newer than the
    # one in the source stack.  If the package in the source stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned then there is nothing to do because the package in
    # the target stack is already newer.

    if ($target > $source) {
        if ( $source->is_pinned() ) {
            $self->whine("$source is pinned to a version older than $target");
            return;
        }
        $self->debug("$target is already newer than $source");
        return;
    }


    # CASE 4:  The package in the target stack is older than the
    # one in the source stack.  If the package in the target stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned, then upgrade the package in the target stack with
    # the newer package in the source stack.

    if ($target < $source) {
        if ( $target->is_pinned() ) {
            $self->whine("$target is pinned to a version older than $source");
            return;
        }
        $self->debug("Merging $source over $target");
        $target->package( $source->package() );
        $target->update();
        return;
    }

    # CASE 5:  If we get here then something has gone wrong

    confess "Unable to merge $source into $target";

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
