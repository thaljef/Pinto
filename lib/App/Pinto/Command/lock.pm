# ABSTRACT: mark a stack as read-only

package App::Pinto::Command::lock;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'stack|s=s' => 'Lock this stack' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{ $args } > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT lock [OPTIONS]

=head1 DESCRIPTION

This command locks a stack so that its packages cannot be changed. It
is typically used with the L<copy|App::Pinto::Command::copy> command
to effectively create a read-only "tag" of a stack.

To unlock a stack, use the L<unlock|App::Pinto::Command::unlock> 
command.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the
stack as an argument. So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT lock --stack dev
  pinto --root REPOSITORY_ROOT lock dev

A stack specified as an argument in this fashion will override any
stack specified with the C<--stack> option.  If a stack is not
specified by neither argument nor option, then it defaults to the
stack that is currently marked as the default stack.

=head1 COMMAND OPTIONS

=over 4

=item --stack NAME

=item -s NAME

Lock the stack with the given NAME.  Defaults to the name of whichever
stack is currently marked as the default stack.  Use the
L<stacks|App::Pinto::Command::stacks> command to see the stacks in the
repository.

=back

=cut
