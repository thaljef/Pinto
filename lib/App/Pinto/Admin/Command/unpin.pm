package App::Pinto::Admin::Command::unpin;

# ABSTRACT: free a package that has been pinned

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
        [ 'message|m=s' => 'Message for the revision log' ],
        [ 'stack|s=s'   => 'Name of stack to unpin' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] TARGET ...
%c --root=PATH $command [OPTIONS] < LIST_OF_TARGETS
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

  pinto-admin --root=/some/dir unpin [OPTIONS] TARGET ...
  pinto-admin --root=/some/dir unpin [OPTIONS] < LIST_OF_TARGETS

=head1 DESCRIPTION

This command unpins a package in the stack, so that the package can be
merged into another stack with a newer version of the package, or the
package can be upgraded to a newer version within this stack.

=head1 COMMAND ARGUMENTS

Arguments are the names of the packages you wish to unpin.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Use the given MESSAGE as the revision log message.

=item --stack=NAME

Unpin the package on the stack with the given NAME.  Defaults to C<default>.

=back

=cut
