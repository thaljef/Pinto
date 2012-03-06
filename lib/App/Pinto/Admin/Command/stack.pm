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

Every L<Pinto> repository has a built-in stack named C<default>.  Most
commands and subcommands that take a C<--stack> option or
C<STACK_NAME> argument will use the C<default> stack if you don't
specify an explicit stack.  The C<default> stack is always present and
cannot be removed.

=head1 SEE ALSO

L<pinto-admin> for global command options.

=cut
