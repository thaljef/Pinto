package App::Pinto::Admin::Command::add;

# ABSTRACT: add your own Perl distributions to the repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

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
    return "%c [global options] $command [command options] DISTRIBUTION";
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify one or more distribution args") if not @{ $args };
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;
    $self->pinto( $opts )->add( dists => $args );
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
