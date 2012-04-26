# ABSTRACT: merge one stack into another

package App::Pinto::Admin::Subcommand::stack::merge;

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
        [ 'message|m=s'     => 'Message for the revision log'  ],
    );
}

#------------------------------------------------------------------------------
sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify FROM_STACK and TO_STACK')
        if @{$args} != 2;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] FROM_STACK TO_STACK
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my %stacks = ( from_stack => $args->[0], to_stack => $args->[1] );
    my $result = $self->pinto->run($self->action_name, %{$opts}, %stacks);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack merge [OPTIONS] SOURCE_STACK TARGET_STACK

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

Conflicts will be reported, but the stacks will not be merged and the
repository will not be changed.

=item --message=MESSAGE

Use the given MESSAGE for the revision log message.

=back

=cut
