package App::Pinto::Command::upgrade;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

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
    $self->pinto()->upgrade(remote => $opts->{remote});
    $self->pinto()->clean() unless $self->config()->{_}->{noclean};
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
