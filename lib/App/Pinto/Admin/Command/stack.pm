package App::Pinto::Admin::Command::stack;

# ABSTRACT: manage stacks within the repository

#-----------------------------------------------------------------------------

use base qw(App::Cmd::Subdispatch App::Pinto::Admin::Command);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub plugin_search_path {
    return 'App::Pinto::Admin::Subcommand::stack';
}

#-----------------------------------------------------------------------------

sub prepare_default_command {
    my ( $self, $opt, @args ) = @_;
    $self->_prepare_command( 'help' );
}

#-----------------------------------------------------------------------------

1;

__END__
