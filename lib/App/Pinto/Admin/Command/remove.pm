package App::Pinto::Admin::Command::remove;

# ABSTRACT: remove your own packages from the repository

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ "author=s"  => 'Your author ID (like a PAUSE ID)' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    return "%c [global options] $command [command options] PACKAGE";
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    my @args = @{$args} ? @{$args} : Pinto::Util::args_from_fh(\*STDIN);
    die "Nothing to do\n" if not @args;

    $self->pinto( $opts )->remove( packages => \@args );
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
