# ABSTRACT: force a package to stay in a stack

package App::Pinto::Command::pin;

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'dry-run'     => 'Do not commit any changes'           ],
        [ 'message|m=s' => 'Message to describe the change'      ],
        [ 'stack|s=s'   => 'Pin targets to this stack'           ],
        [ 'use-default-message|M' => 'Use the generated message' ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT pin [OPTIONS] TARGET ...

=head1 DESCRIPTION

This command pins a package so that it cannot be changed even if a
different version is added or pulled to the stack The pin is local
to the stack and does not affect any other stacks.

A package must be registered on the stack before you can pin it.  To bring a
package onto the stack, use the L<pull|App::Pinto::Command::pull> or 
L<register|App::Pinto::Command::register> commands.  To remove the pin
from a package, see the L<unpin|App::Pinto::Command::unpin> command.

When pinning, all its sister packages in that distribution also become 
pinned.  Pinned packages also cannot be unregistered from the stack
or deleted from the repository without the C<--force> option.

=head1 COMMAND ARGUMENTS

Arguments are the targets you wish to unpin.  Targets can be
specified as packages or distributions, such as:

  Some::Package
  Some::Other::Package

  AUTHOR/Some-Dist-1.2.tar.gz
  AUTHOR/Some-Other-Dist-1.3.zip

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --dry-run

Go through all the motions, but do not actually commit any changes to
the repository.  Use this option to see how the command would
potentially impact the stack.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you
will be prompted to enter the message via your text editor.  Use the
C<EDITOR> or C<VISUAL> environment variables to control which editor
is used.  A log message is not required whenever the C<--dry-run>
option is set, or if the action did not yield any changes to the
repository.

=item --stack=NAME

Pins the package on the stack with the given NAME.  Defaults to the
name of whichever stack is currently marked as the default stack.  Use
the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto
will generate a semi-informative log message just based on the command
and its arguments.  If you set an explicit message with C<--message>,
the C<--use-default-message> option will be silently ignored.

=back

=cut
