package App::Pinto::Admin::Subcommand::stack::copy;

# ABSTRACT: create a new stack by copying another

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
        [ 'description|d=s' => 'Long(er) description of the stack' ],
        [ 'message|m=s'     => 'Prepend a message to the VCS log'  ],
        [ 'nocommit'        => 'Do not commit changes to VCS'      ],
        [ 'noinit'          => 'Do not pull/update from VCS'       ],
        [ 'tag=s'           => 'Specify a VCS tag name'            ],
    );


}

#------------------------------------------------------------------------------
sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify FROM_STACK_NAME and TO_STACK_NAME')
        if @{$args} != 2;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] FROM_STACK_NAME TO_STACK_NAME
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch(%{$opts});
    my %stacks = ( from_stack => $args->[0], to_stack => $args->[1] );
    $self->pinto->add_action($self->action_name(), %{$opts}, %stacks);
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack copy [OPTIONS] STACK_NAME NEW_STACK_NAME

=head1 DESCRIPTION

This command creates a new stack by copying an existing one.  All the
pins from the existing stack will also be copied to the new one.  The
new stack must not already exist.

Please see the C<remove> subcommand to remove a stack, or see the
C<create> subcommand to create a new empty stack.

=head1 SUBCOMMAND ARGUMENTS

The two required arguments are the name of the source and target stacks.
Stack names must be alphanumeric (including "-" or "_") and will be
forced to lowercase.

=head1 SUBCOMMAND OPTIONS

=over 4

=item --description=TEXT

Annotates this stack with a descriptive explanation for why this stack
was created.  For example: "Experimenting with a new version of
Foo::Bar".  If you do not specify a description, the new stack will
just get the same description as the original.

=item --message=MESSAGE

Prepends the MESSAGE to the VCS log message that L<Pinto> generates.
This is only relevant if you are using a VCS-based storage mechanism
for L<Pinto>.

=item --nocommit

Prevents L<Pinto> from committing changes in the repository to the VCS
after the operation.  This is only relevant if you are
using a VCS-based storage mechanism.  Beware this will leave your
working copy out of sync with the VCS.  It is up to you to then commit
or rollback the changes using your VCS tools directly.  Pinto will not
commit old changes that were left from a previous operation.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item --tag=NAME

Instructs L<Pinto> to tag the head revision of the repository at
C<NAME>.  This is only relevant if you are using a VCS-based storage
mechanism.  The syntax of the C<NAME> depends on the type of VCS you
are using.

=back

=cut
