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
        [ 'dry-run'                   => 'Do not commit any changes' ],
        [ 'force'                     => 'Revert even if revision is not ancestor' ],
        [ 'message|m=s'               => 'Message to describe the change' ],
        [ 'stack|s=s'                 => 'Revert this stack' ],
        [ 'use-default-message|M'     => 'Use the generated message' ],
    );

}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    my $arg_count = @{$args};

    # If there is one arg, then it is revision and stack is default
    # If there are 2 args, then the 1st is stack and 2nd is revision

    $opts->{revision} = $arg_count == 1 ? $args->[0] : $args->[1];
    die "You cannot set the stack both via a flag and positionally\n"
        if $opts->{stack} && $arg_count == 2;

    $opts->{stack} = $args->[0] if $arg_count == 2;

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT revert [OPTIONS] [STACK] [REVISION]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command restores the head of the stack to a prior state by creating a new
revision that matches the prior state.  See the
L<reset|App::Pinto::Command::reset> command to move the head back to a prior
state and discard subsequent revisions.

=head1 COMMAND ARGUMENTS

The arguments are the name of the stack and/or the id of the revision to
revert to.  If the revision id is not specified, it defaults to the immediate
parent of head revision of the stack.  If the stack is not specified, then it
defaults to whichever stack is currently marked as the default.  The stack can
also be specified using the C<--stack> option.  Some examples:

  pinto ... revert                   # Revert default stack to previous revision
  pinto ... revert af01256e          # Revert default stack to revision af01256e
  pinto ... revert mystack af01256e  # Revert mystack to revision af0125e

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to the
repository.  At the conclusion, a diff showing the changes that would have
been made will be displayed.  Use this option to see how upgrades would
potentially impact the stack.

=item --force

Force reversion even if the revision is not actually an ancestor.  Normally,
you can only revert to a revision that the stack has actually been at.  This
option only has effect if you specify a target revision argument.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you will be
prompted to enter the message via your text editor.  Use the C<PINTO_EDITOR>
or C<EDITOR> or C<VISUAL> environment variables to control which editor is
used.  A log message is not required whenever the C<--dry-run> option is set,
or if the action did not yield any changes to the repository.

=item --stack=NAME

=item -s NAME

Peform reversion on the stack with the given NAME.  Defaults to the name of
whichever stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stacks> command to see the stacks in the
repository.  This option is silently ignored if the stack is specified as a
command argument instead.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto will
generate a semi-informative log message just based on the command and its
arguments.  If you set an explicit message with C<--message>, the C<--use-
default-message> option will be silently ignored.

=back

=cut
