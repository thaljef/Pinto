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
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'reason|R=s'  => 'Explanation of why this package is pinned' ],
        [ 'stack|s=s'   => 'Pin this package within a particular stack' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] PACKAGE_NAME ...
%c --root=PATH $command [OPTIONS] < LIST_OF_PACKAGE_NAMES
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @args;

    $self->pinto->new_batch( %{$opts} );

    for my $arg (@args) {
        my ($name, $version) = split m/ - /mx, $arg, 2;
        my %version = defined $version ? (version => $version) : ();
        $self->pinto->add_action($self->action_name(), %{$opts}, package => $name, %version);
    }
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto-admin --root=/some/dir pin [OPTIONS] PACKAGE_NAME ...
  pinto-admin --root=/some/dir pin [OPTIONS] < LIST_OF_PACKAGE_NAMES

=head1 DESCRIPTION

This command pins a package so that it stays in the stack even if a
newer version is subsequently mirrored, imported, or added to that
stack.  The pin is local to the stack and does not affect any other
stacks.

A package must be in the stack before you can pin it.  To add a
package to the stack, please see the C<push> command.  To remove the
pin from a package, please see the C<unpin> command.

=head1 COMMAND ARGUMENTS

Arguments are the names of the packages you wish to pin.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  Beware this will leave your working copy
out of sync with the VCS.  It is up to you to then commit or rollback
the changes using your VCS tools directly.  Pinto will not commit old
changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --reason=TEXT

Annotates the pin with a descriptive explanation for why this package
is pinned.  For example: 'Versions later than 2.1 will break our app'

=item --stack=NAME

Instructs L<Pinto> to pin the package on the stack named C<NAME>.  If
not specified, the C<default> stack is assumed.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at
C<NAME>.  This is only relevant if you are using a VCS-based storage
mechanism.  The syntax of the C<NAME> depends on the type of VCS you
are using.

=back

=cut
