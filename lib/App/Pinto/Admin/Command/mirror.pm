package App::Pinto::Admin::Command::mirror;

# ABSTRACT: get the latest distributions from a CPAN mirror

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ 'force'     => 'Force update, even if indexes appear unchanged' ],
        [ 'mirror=s'  => 'URL of a CPAN mirror (or another Pinto repository)' ],
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
