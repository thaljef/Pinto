# ABSTRACT: revert stack to a prior revision

package App::Pinto::Command::revert;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw(revert) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'dry-run'    => 'Do not commit any changes' ],
        [ 'force'      => 'Revert even if revision is not ancestor' ],
        [ 'stack|s=s'  => 'Revert this stack' ],
    );

}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    my $arg_count = @{$args};

    $opts->{revision} = $arg_count == 1 ? $args->[0] : $args->[1];

    $opts->{stack} = $args->[0] if $arg_count == 2;

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT revert [OPTIONS] [REVISION]

=head1 DESCRIPTION

This command creates a new revision that reverts the stack to a prior
revision.

=head1 COMMAND ARGUMENTS

The arguments are the name of the stack and/or the id of the revision to
revert to.  If the revision id is not specified, it defaults to the immediate
parent of head revision of the stack.  If the stack is not specified, then it
defaults to whichever stack is currently marked as the default.  The stack can
also be specified using the C<--stack> option.

  # Revert default stack to previous revision
  pinto --root REPOSITORY_ROOT revert

  # Revert default stack to a particular revision
  pinto --root REPOSITORY_ROOT revert af01256e

  # Revert a particular stack to a particular revision
  pinto --root REPOSITORY_ROOT revert mystack af01256e

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to the
repository.  At the conclusion, a diff showing the changes that would have
been made will be displayed.  Use this option to see how upgrades would
potentially impact the stack.

=item --force

Force reversion even if the revision is not actually an ancestor.  Normally,
you can only revert to a revision that the stack has actually been at.

=item --stack=NAME

=item -s NAME

Peform revision on the stack with the given NAME.  Defaults to the name of
whichever stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stacks> command to see the stacks in the
repository.  This option is silently ignored if stack is specified as a
command argument instead.


=back

=cut
