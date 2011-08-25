package App::Pinto::Admin::Command;

# ABSTRACT: Base class for pinto-admin commands

use strict;
use warnings;

#-----------------------------------------------------------------------------

use App::Cmd::Setup -command;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (

        [ 'man' => 'Show manual for this command' ],
    );
}

#-----------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    die "RTFM!\n" if $opts->{man};
}

#-----------------------------------------------------------------------------

=method pinto()

Returns the Pinto object for this command.  Basically an alias for

  $self->app();

=cut

sub pinto {
    my ($self) = @_;
    return $self->app->pinto();
}

#-----------------------------------------------------------------------------


1;

__END__
