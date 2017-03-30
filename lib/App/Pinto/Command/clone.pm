# ABSTRACT: clone a new stack from a different repository

package App::Pinto::Command::clone;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'default'         => 'Make the new stack the default stack' ],
        [ 'description|d=s' => 'Brief description of the stack' ],
        [ 'lock'            => 'Lock the new stack to prevent changes' ],
    );

}

#------------------------------------------------------------------------------
sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Must specify STACK and TO_STACK')
        if @{$args} != 2;

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ( $self, $opts, $args ) = @_;

    my %targets = ( upstream => $args->[0], to_stack => $args->[1] );
    my $result = $self->pinto->run( $self->action_name, %{$opts}, %targets );

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT clone [OPTIONS] UPSTREAM TO_STACK

=head1 DESCRIPTION

This command creates a new stack by cloning a stack on an upstream repository.
The new stack must not already exist.

Use the L<new|App::Pinto::Command::new> command to create a new empty
stack, or the L<props|App::Pinto::Command::props> command to change
a stack's properties after it has been created.

=head1 COMMAND ARGUMENTS

The two required arguments are the URL of stack on the upstream repository and target
stack.  The URL could be something like:

    https://www.stratopan.com/thaljef/OpenSource/pinto-release 

Stack names must be alphanumeric plus hyphens, underscores, and periods, and
are not case-sensitive.

=head1 COMMAND OPTIONS

=over 4

=item --default

Also mark the new stack as the default stack.

=item --description=TEXT

=item -d TEXT

Use TEXT for the description of the stack.  If not specified, defaults
to 'Clone of stack UPSTREAM'.

=item --lock

Also lock the new stack to prevent future changes.  This is useful for
creating a read-only "tag" of a stack.  You can always use the
L<lock|App::Pinto::Command::lock> or
L<unlock|App::Pinto::Command::unlock> commands at a later time.

=back

=cut
