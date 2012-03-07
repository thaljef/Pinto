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
        [ 'message|m=s' => 'Prepend a message to the VCS log' ],
        [ 'nocommit'    => 'Do not commit changes to VCS' ],
        [ 'noinit'      => 'Do not pull/update from VCS' ],
        [ 'tag=s'       => 'Specify a VCS tag name' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH $command [OPTIONS] STACK_NAME PACKAGE_NAME ...
%c --root=PATH $command [OPTIONS] STACK_NAME < LIST_OF_PACKAGE_NAMES
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a STACK_NAME and at least one PACKAGE_NAME")
        if @{ $args } < 2;

    return 1;

}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $stack_name = shift @{ $args };

    my @package_names = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    return 0 if not @package_names;

    $self->pinto->new_batch( %{$opts} );

    for my $package_name (@package_names) {
        $self->pinto->add_action($self->action_name(), %{$opts}, package => $package_name,
                                                                 stack   => $stack_name );
    }

    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------

1;

__END__


=head1 SYNOPSIS

  pinto-admin --root=/some/dir unpin [OPTIONS] PACKAGE_NAME ...
  pinto-admin --root=/some/dir unpin [OPTIONS] < LIST_OF_PACKAGE_NAMES

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

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at C<NAME>.
This is only relevant if you are using a VCS-based storage mechanism.
The syntax of the C<NAME> depends on the type of VCS you are using.

=back

=cut
