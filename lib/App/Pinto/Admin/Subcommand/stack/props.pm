# ABSTRACT: show stack properties

package App::Pinto::Admin::Subcommand::stack::props;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Cannot specify multiple stacks')
        if @{$args} > 1;

    return 1;
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS] [STACK]
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my $stack = $args->[0] || 'default';
    my $result = $self->pinto->run($self->action_name, %{$opts}, stack => $stack);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack props [OPTIONS] STACK

=head1 DESCRIPTION

This command shows the properties of a stack.  See the C<edit>
subcommand to change the properties.

=head1 SUBCOMMAND ARGUMENTS

The one argument is the name of the stack you wish to see the
properties for.  If you do not specify a stack, it defaults to
'default'.  Stack names must be alphanumeric (including "-" or "_")
and will be forced to lowercase.

=head1 SUBCOMMAND OPTIONS

NONE

=cut

