package App::Pinto::Command::update;

# ABSTRACT: Fill your repository with the latest archives from a CPAN mirror

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ "remote=s"  => 'URL of a CPAN mirror' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Arguments are not allowed") if @{ $args };
}

#------------------------------------------------------------------------------

sub execute {
    $DB::single = 1;
    my ($self, $opts, $args) = @_;
    $self->pinto()->update(remote => $opts->{remote});
    $self->pinto()->clean() unless $self->config()->{_}->{noclean};
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
