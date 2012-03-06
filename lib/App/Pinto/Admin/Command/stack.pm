package App::Pinto::Admin::Command::stack;

# ABSTRACT: manage stacks within the repository

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::DispatchingCommand';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub prepare_default_command {
    my ( $self, $opt, @args ) = @_;
    $self->_prepare_command( 'help' );
}

#-----------------------------------------------------------------------------

1;

__END__
