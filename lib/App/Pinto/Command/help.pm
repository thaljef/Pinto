# ABSTRACT: display a command's help screen

package App::Pinto::Command::help;

use strict;
use warnings;

use base qw(App::Cmd::Command::help);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# This is just a thin subclass of App::Cmd::Command::help.  All we have done is
# extend the exeucte() method to mention the "pinto manual" command at the end

sub execute {
    my ($self, $opts, $args) = @_;

    my ($cmd, undef, undef) = $self->app->prepare_command(@$args);
    my ($cmd_name) = $cmd->command_names;

    my $rv = $self->SUPER::execute($opts, $args);

    # Only display this if showing help for a specific command.
    print qq{For more information, run "pinto manual $cmd_name"\n} if @{$args};

    return $rv;
}

#-------------------------------------------------------------------------------
1;

=head1 SYNOPSIS

  pinto help COMMAND

=head1 DESCRIPTION

This command shows a brief help screen for a pinto COMMAND.

=head1 COMMAND ARGUMENTS

The argument to this command is the name of the command you would like help
on.  You can also use the L<manual|App::Pinto::Command::manual> command to get
extended documentation for any command.

=cut
