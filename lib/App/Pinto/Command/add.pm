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
        [ "author=s"  => 'Your PAUSE ID' ],
    );
}

#------------------------------------------------------------------------------

sub usage_desc {
    my ($self) = @_;
    my ($command) = $self->command_names();
    return "%c [global options] $command [command options] ARCHIVE [ARCHIVE...]";
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Must specify one or more file arguments")
      if not @{ $args };
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;
    $self->pinto()->add(author => $opts->{author}, file => $_) for @{ $args };
    $self->pinto()->clean() unless $self->pinto()->config()->get('nocleanup');
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
