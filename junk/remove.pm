# ABSTRACT: delete a stack

package App::Pinto::Admin::Subcommand::stack::remove;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(remove rm delete del) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'message|m=s' => 'Message for the revision log'  ],
        [ 'force'       => 'Delete even if not merged'  ],
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
%c --root=PATH stack $command [OPTIONS] STACK_NAME
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

  pinto-admin --root=/some/dir stack remove [OPTIONS] STACK_NAME

=head1 DESCRIPTION

This command removes a stack from the repository.  It only removes the
stack itself, not the packages that were in it.

=head1 SUBCOMMAND ARGUMENTS

The single required argument is the name of the stack that you want
to remove.

=head1 SUBCOMMAND OPTIONS

=over 4

=item --force

Delete the stack, even if it has not been fully merged to another
stack (NOT YET IMPLIMENTED).

=item --message=MESSAGE

Use the given MESSAGE as the revision log message.

=back

=cut
