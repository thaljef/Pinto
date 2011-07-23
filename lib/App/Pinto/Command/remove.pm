package App::Pinto::Command::remove;

# ABSTRACT: remove your own packages from the repository

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ "author=s"  => 'Your PAUSE ID' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Must specify one or more package arguments") unless @{ $args };
}

#------------------------------------------------------------------------------

sub execute {
    $DB::single = 1;
    my ($self, $opts, $args) = @_;
    $self->pinto()->remove(author => $opts->{author}, package => $_) for @{ $args };
    $self->pinto()->clean() unless $self->config()->{_}->{noclean};
    return 0;
}

1;

__END__
