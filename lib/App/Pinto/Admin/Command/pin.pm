package App::Pinto::Admin::Command::pin;

# ABSTRACT: force a package to stay in a stack

use strict;
use warnings;

use Pinto::Util;

#------------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'stack|s=s'   => 'Stack on which to pin the target' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] TARGET ...
%c --root=PATH $command [OPTIONS] < LIST_OF_TARGETSS
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto-admin --root=/some/dir pin [OPTIONS] STACK_NAME PACKAGE_NAME ...
  pinto-admin --root=/some/dir pin [OPTIONS] STACK_NAME < LIST_OF_PACKAGE_NAMES

=head1 DESCRIPTION

This command pins a package so that it stays in the stack even if a
newer version is subsequently mirrored, imported, or added to that
stack.  The pin is local to the stack and does not affect any other
stacks.

A package must be in the stack before you can pin it.  To bring a
package into the stack, use the C<pull> command.  To remove the pin
from a package, please see the C<unpin> command.

=head1 COMMAND ARGUMENTS

Arguments are the names of the packages you wish to pin.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --stack=NAME

Name of the stack on which to pin the target.  Defaults to 'default'.

=back

=cut
