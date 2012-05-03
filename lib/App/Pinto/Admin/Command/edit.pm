# ABSTRACT: change stack properties

package App::Pinto::Admin::Command::edit;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {

    return (
        ['default'             => 'mark stack as the default'     ],
        ['properties|props=s%' => 'name=value pairs of properties'],
    );
}

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

    my $stack = $args->[0];
    my $result = $self->pinto->run($self->action_name, %{$opts},
                                                       stack => $stack);

    return $result->exit_status;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto-admin --root=/some/dir stack edit [OPTIONS] [STACK]

=head1 DESCRIPTION

This command edits the properties of a stack.  See the
L<props|App::Pinto::Admin::Command::props> command to display stack
properties.

=head1 COMMAND ARGUMENTS

The argument is the name of the stack you wish to edit the properties
for.  If you do not specify a stack, it defaults to whichever stack is
currently marked as default.  Stack names must be alphanumeric
(including "-" or "_") and will be forced to lowercase.

=head1 COMMAND OPTIONS

=over 4

=item --default

Causes the selected stack to be marked as the "default".  The
"default" stack becomes the default for all operations where you do no
not specify an explicit stack.  The default stack also governs the
index file for your repository.  DO NOT CHANGE THE DEFAULT STACK
WITHOUT DUE DILLIGENCE.  It has broad impact, especially if your
repository has multiple users.

=item --properties name1=value1

=item --props name1=value1

Specifies property names and values.  You can repeat this option to
set multiple properties.  If the property with that name does not
already exist, it will be created.  Property names must be
alphanumeric, and may not contain spaces.  They will also be forced to
lowercase.  Properties starting with the prefix 'pinto:' are reserved
for internal use, SO DO NOT CHANGE THEM.

=back

=cut

