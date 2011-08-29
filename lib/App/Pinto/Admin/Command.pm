package App::Pinto::Admin::Command;

# ABSTRACT: Base class for pinto-admin commands

use strict;
use warnings;

use Pod::Usage qw(pod2usage);

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

sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    return '%c --repos=PATH $command [OPTIONS] [ARGS]'
}

#-----------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->show_manual_and_exit() if $opts->{man};

    return 1;
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

sub show_manual_and_exit {
    my ($self) = @_;
    my $class = ref $self;
    (my $relative_path = $class) =~ s< :: ></>xmsg;
    $relative_path .= '.pm';

    my $absolute_path = $INC{$relative_path};
    die "No manual available for $class" if not $absolute_path;  ## no critic qw(Carping)

    pod2usage(-verbose => 2, -input => $absolute_path, -exitval => 0);

    return 1;
}

#-----------------------------------------------------------------------------


1;

__END__
