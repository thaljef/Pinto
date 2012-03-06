package App::Pinto::Admin::DispatchingCommand;

# ABSTRACT: Base class for pinto-admin commands that redispatch to subcommands

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base qw(App::Cmd::Subdispatch App::Pinto::Admin::Command);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub plugin_search_path {
    my ($self) = @_;

    my $prefix    = $self->subcommand_namespace_prefix();
    my ($command) = $self->command_names();

    return "${prefix}::${command}";
}

#-----------------------------------------------------------------------------

sub subcommand_namespace_prefix {
    return 'App::Pinto::Admin::Subcommand';
}

#-----------------------------------------------------------------------------

1;

__END__
