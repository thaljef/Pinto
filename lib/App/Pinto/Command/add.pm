package App::Pinto::Command::add;

# ABSTRACT: add your own Perl archives to the repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    return (
        [ "author=s"  => 'Your author ID (like a PAUSE ID)' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;
    my ($command) = $self->command_names();
    return "%c [global options] $command [command options] ARCHIVE";
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify exactly one archive") if @{ $args } != 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;
    $self->pinto( $opts )->add( file => $args->[0] );
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
