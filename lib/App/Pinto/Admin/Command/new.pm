# ABSTRACT: create a new empty stack

package App::Pinto::Admin::Command::new;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'description|d=s' => 'Brief description of the stack' ],
    );


}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify exactly one stack')
        if @{$args} != 1;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] STACK
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $result = $self->pinto->run($self->action_name, %{$opts},
                                                       stack => $args->[0]);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack create [OPTIONS] STACK

=head1 DESCRIPTION

This command creates a new empty stack.

Please see the L<copy|App::Pinto::Admin::Command::copy> command to
create a new stack from another one, or the
L<edit:App::Pinto::Admin::Command::copy> subcommand to change a
stack's properties after it has been created.

=head1 COMMAND ARGUMENTS

The required argument is the name of the stack you wish to create.
Stack names must be alphanumeric (including "-" or "_") and will be
forced to lowercase.

=head1 COMMAND OPTIONS

=over 4

=item --description=TEXT

Annotates this stack with a description of its purpose.

=back

=cut

