# ABSTRACT: create a new stack by copying another

package App::Pinto::Admin::Subcommand::stack::copy;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(copy cp) }

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

    $self->usage_error('Must specify FROM_STACK and TO_STACK')
        if @{$args} != 2;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] FROM_STACK TO_STACK
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my %stacks = ( from_stack => $args->[0], to_stack => $args->[1] );
    my $result = $self->pinto->run($self->action_name, %{$opts}, %stacks);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack copy [OPTIONS] FROM_STACK TO_STACK

=head1 DESCRIPTION

This command creates a new stack by copying an existing one.  All the
pins and properties from the existing stack will also be copied to the
new one.  The new stack must not already exist.

Please see the C<stack create> subcommand to create a new empty stack, or
the C<stack edit> subcommand to change a stack's properties after it has
been created.

=head1 SUBCOMMAND ARGUMENTS

The two required arguments are the name of the source and target
stacks.  Stack names must be alphanumeric (including "-" or "_") and
will be forced to lowercase.

=head1 SUBCOMMAND OPTIONS

=over 4

=item --description=TEXT

Annotates the new stack with a brief description of its purpose.

=back

=cut
