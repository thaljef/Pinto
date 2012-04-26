# ABSTRACT: create a new empty stack

package App::Pinto::Admin::Subcommand::stack::create;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(create new) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'description|d=s' => 'Brief description of the stack' ],
        [ 'message|m=s'     => 'Message for the revision log'   ],
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

    my $result = $self->pinto->run($self->action_name, %{$opts}, stack => $args->[0]);

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

Please see the C<remove> subcommand to remove a stack, or see the
C<copy> subcommand to create a new stack from another one.

=head1 SUBCOMMAND ARGUMENTS

The one required argument is the name of the stack you wish to create.
Stack names must be alphanumeric (including "-" or "_") and will be
forced to lowercase.

=head1 SUBCOMMAND OPTIONS

=over 4

=item --description=TEXT

Annotates this stack with a description of its purpose.

=item --message=MESSAGE

Use the given MESSAGE as the revision log message.

=back

=cut

