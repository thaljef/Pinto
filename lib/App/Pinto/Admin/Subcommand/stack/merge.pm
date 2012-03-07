package App::Pinto::Admin::Subcommand::stack::merge;

# ABSTRACT: merge one stack into another

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(merge) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'dryrun'          => 'Do not actually perform the merge' ],
        [ 'message|m=s'     => 'Prepend a message to the VCS log'  ],
        [ 'nocommit'        => 'Do not commit changes to VCS'      ],
        [ 'noinit'          => 'Do not pull/update from VCS'       ],
        [ 'tag=s'           => 'Specify a VCS tag name'            ],
    );
}

#------------------------------------------------------------------------------
sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify FROM_STACK_NAME and TO_STACK_NAME')
        if @{$args} != 2;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] FROM_STACK_NAME TO_STACK_NAME
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch(%{$opts});
    my %stacks = ( from_stack => $args->[0], to_stack => $args->[1] );
    $self->pinto->add_action($self->action_name(), %{$opts}, %stacks);
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack merge [OPTIONS] SOURCE_STACK_NAME TARGET_STACK_NAME

=head1 DESCRIPTION

This command merges the packages from one stack (the C<SOURCE>) into
another (the C<TARGET>).  Merge rules are as follows:

=over 4

=item * If a package in the C<SOURCE> is newer than the corresponding
package in the C<TARGET>, then the package in the C<TARGET> is
upgraded to the same version as the package in the C<SOURCE>.

=item * If the package in the C<TARGET> is pinned and the
corresponding package in the C<SOURCE> is newer, then a conflict
occurrs.

=item * If the package in the C<SOURCE> is pinned and the
corresponding package in the C<TARGET> is newer, then a conflict
occurrs.

=back

Whenever there is a conflict, the merge is aborted.  All the pins from
the C<SOURCE> are also placed on the C<TARGET>.  Both C<SOURCE> and
C<TARGET> stacks must already exist before merging.  Please see the
C<copy> or C<create> subcommands to create stacks.

=head1 SUBCOMMAND ARGUMENTS

The two required arguments are the name of the C<SOURCE> stack and the
name of the C<TARGET> stack.

=head1 SUBCOMMAND OPTIONS

=over 4

=item --dryrun

Instructs L<Pinto> to do a dry run of the merge.  Conflicts will be
reported, but the stacks will not actually be merged.

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are
using a VCS-based storage mechanism.  Beware this will leave your
working copy out of sync with the VCS.  It is up to you to then commit
or rollback the changes using your VCS tools directly.  Pinto will not
commit old changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at
C<NAME>.  This is only relevant if you are using a VCS-based storage
mechanism.  The syntax of the C<NAME> depends on the type of VCS you
are using.

=back

=cut
