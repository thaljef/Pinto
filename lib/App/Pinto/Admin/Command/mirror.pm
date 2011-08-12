package App::Pinto::Admin::Command::mirror;

# ABSTRACT: get all the latest distributions from a remote repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ 'force'     => 'Force action, even if indexes appear unchanged' ],
        [ 'source=s'  => 'URL of a CPAN mirror (or another Pinto repository)' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;
    $self->usage_error('Arguments are not allowed') if @{ $args };
    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;
    $self->pinto( $opts )->mirror();
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
