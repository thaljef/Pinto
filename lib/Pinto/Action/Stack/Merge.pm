# ABSTRACT: Merge packages from one stack into another

package Pinto::Action::Stack::Merge;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Carp;

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


has dryrun => (
    is       => 'ro',
    isa      => Bool,
    default  => 0,
);

#------------------------------------------------------------------------------
# Methods

sub execute {
    my ($self) = @_;

    my $source_stack_name = $self->from_stack();
    my $source_stack = $self->repos->get_stack(name => $source_stack_name)
        or confess "Stack $source_stack_name does not exist";

    my $target_stack_name = $self->to_stack();
    my $target_stack = $self->repos->get_stack(name => $target_stack_name)
        or confess "Stack $target_stack_name does not exist";

    my $where = { stack => $source_stack->id() };
    my $package_stack_rs = $self->repos->db->select_package_stacks( $where );

    $self->debug("Merging stack $source_stack into stack $target_stack");

    my $conflicts;
    while ( my $source_pkg_stk = $package_stack_rs->next() ) {

        $self->debug("Merging package $source_pkg_stk into stack $target_stack");

        my $where = { 'package.name' => $source_pkg_stk->package->name(),
                      'stack'        => $target_stack->id() };

        my $attrs = { prefetch => 'package' };

        my $target_pkg_stk = $self->repos->db->select_package_stacks($where, $attrs)->single();

        $conflicts += $self->_merge_pkg_stk( $source_pkg_stk, $target_pkg_stk, $target_stack );
    }

    $self->fatal("There were $conflicts conflicts.  Merge aborted")
        if $conflicts and not $self->dryrun();

    $self->info('Dry run merge -- no changes were made')
        if $self->dryrun();

    return $self->result;
}

#------------------------------------------------------------------------------

sub _merge_pkg_stk {
    my ($self, $source, $target, $to_stack) = @_;

    # CASE 1:  The package does not exist in the target stack,
    # so we can go ahead and just add it there.

    if (not defined $target) {
         my $pkg = $source->package();
         $self->info("Adding package $pkg to stack $to_stack");
         return 0 if $self->dryrun();
         $source->copy( {stack => $to_stack} );
         $self->result->changed;
         return 0;
     }

    # CASE 2:  The exact same package is in both the source
    # and the target stacks, so we don't have to merge.  But
    # if the source is pinned, then we should also copy the
    # pin to the target.

    if ($target == $source) {
        $self->notice("$source and $target are the same");
        if ($source->is_pinned) {
            $self->info("Adding pin to $target");
            return 0 if $self->dryrun();
            $target->pin( $source->pin() );
            $target->update();
            $self->result->changed;
            return 0;
        }
        return 0;
    }

    # CASE 3:  The package in the target stack is newer than the
    # one in the source stack.  If the package in the source stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned then there is nothing to do because the package in
    # the target stack is already newer.

    if ($target > $source) {
        if ( $source->is_pinned() ) {
            $self->warning("$source is pinned to a version older than $target");
            return 1;
        }
        $self->info("$target is already newer than $source");
        return 0;
    }


    # CASE 4:  The package in the target stack is older than the
    # one in the source stack.  If the package in the target stack
    # is pinned, then we have a conflict, so whine.  If it is not
    # pinned, then upgrade the package in the target stack with
    # the newer package in the source stack.

    if ($target < $source) {
        if ( $target->is_pinned() ) {
            $self->warning("$target is pinned to a version older than $source");
            return 1;
        }
        my $source_pkg = $source->package();
        $self->info("Upgrading $target to $source_pkg");
        return 0 if $self->dryrun();
        $target->package( $source_pkg );
        $target->update();
        $self->result->changed;
        return 0;
    }

    # CASE 5:  The above logic should cover all possible scenarios.
    # So if we get here then either our logic is flawed or something
    # weird has happened in the database.

    confess "Unable to merge $source into $target";

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
