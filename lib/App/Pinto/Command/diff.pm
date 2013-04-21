#ABSTRACT: show difference between two stacks

package App::Pinto::Command::diff;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw(diff) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return ();
}

#------------------------------------------------------------------------------
sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Must specify at least one stack') if @{$args} < 1;

    $self->usage_error('Cannot specify more than two stacks') if @{$args} > 2;
    
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    # If there's only one stack, then the
    # left stack is the default (i.e. undef)
    unshift @{$args}, undef if @{$args} == 1;

    my %stacks = ( left_stack => $args->[0], right_stack => $args->[1] );
    my $result = $self->pinto->run($self->action_name, %{$opts}, %stacks);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT diff [OPTIONS] [LEFT_STACK] RIGHT_STACK

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command shows the difference between two stacks, presented in a
format similar to diff[1].

=head1 COMMAND ARGUMENTS

Command arguments are the names of the stacks to compare.  If you only
specify one argument, then it is assumed to be the right stack and
whichever stack is currently marked as the default will be used as
the left stack.  All comparisons are made between the head revisions
of each stack.

=head1 COMMAND OPTIONS

None.

=cut
