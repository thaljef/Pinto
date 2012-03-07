package App::Pinto::Admin::Command::stack;

# ABSTRACT: manage stacks within the repository

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::DispatchingCommand';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub prepare_default_command {
    my ( $self, $opt, @args ) = @_;
    $self->_prepare_command( 'help' );
}

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/path/to/repos [global options] stack COMMAND [command options] [ARGS]

=head1 DESCRIPTION

The C<stack> command provides several subcommands for managing stacks.
Each stack is a subset of the packages within the repository.  Stacks
are used to manage the evolution of your dependencies.  You can
"branch" and "merge" stacks, much like a version control system.
Typical stack names are things like "development" or "production" or
"feature-xyz".

=head1 SUBCOMMANDS

The C<stack> command supports several subcommands that perform various
operations on your repository, or report information about your
repository.  To get a listing of all the available subcommands:

  $> pinto-admin stack commands

Each subcommand has its own options and arguments.  To get a brief
summary:

  $> pinto-admin stack help SUBCOMMAND

To see the complete manual for a subcommand:

  $> pinto-admin stack manual SUBCOMMAND

=head1 THE DEFAULT STACK

Every package added to the repository must go into a stack.  But if
that stack has pins that conflict with the incoming packages, then
L<Pinto> will refuse to add all the packages in the archive to the
stack.  But we don't want to lose that archive because it may not be
available in the future.

L<Pinto> has a built-in stack named C<default>.  You cannot pin
packages on the C<default> stack nor can you delete the C<default>
stack.  So the C<default> stack provides a safe landing place for
packages so L<Pinto> never has to completely reject an archive that
has conflicting packages.  Whenever you add a package to a custom
stack, L<Pinto> automatically adds it to the C<default> stack as well.

If there was a conflict in your custom stack, the package will still
be in the repository under the C<default> stack.  Once you've resolved
the conflict (usually by removing the right pins) then you can put the
new packages into your custom stack without having to go get another
copy of the archive (which may not exist by now).

=head1 SEE ALSO

L<pinto-admin> for global command options.

=cut
