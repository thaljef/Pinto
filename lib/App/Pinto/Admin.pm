package App::Pinto::Admin;

# ABSTRACT: Command-line driver for Pinto::Admin

use strict;
use warnings;

use Class::Load;

use List::Util qw(min);
use Log::Dispatch::Screen;
use Log::Dispatch::Screen::Color;

use Pinto::Constants qw(:all);

use App::Cmd::Setup -app;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub global_opt_spec {

    return (
        [ 'root|r=s'    => 'Path to your repository root directory'  ],
        [ 'nocolor'     => 'Do not colorize diagnostic messages'     ],
        [ 'quiet|q'     => 'Only report fatal errors'                ],
        [ 'verbose|v+'  => 'More diagnostic output (repeatable)'     ],
    );

    # TODO: Add options for color contols!
}

#------------------------------------------------------------------------------

=method pinto()

Returns a reference to a L<Pinto> object that has been constructed for
this application.

=cut

sub pinto {
    my ($self) = @_;

    return $self->{pinto} ||= do {
        my %global_options = %{ $self->global_options() };

        $global_options{root} ||= $ENV{PINTO_REPOSITORY_ROOT}
            || $self->usage_error('Must specify a repository root directory');

        my $pinto_class = $self->pinto_class();
        Class::Load::load_class($pinto_class);

        my $pinto = $pinto_class->new(%global_options);
        $pinto->add_logger($self->logger(%global_options));

        $pinto;
    };
}

#------------------------------------------------------------------------------

sub logger {
    my ($self, %options) = @_;

    my $nocolor   = $options{nocolor};
    my $colors    = $nocolor ? {} : ($self->log_colors);
    my $log_class = 'Log::Dispatch::Screen';
    $log_class .= '::Color' unless $nocolor;

    my $verbose = min($options{verbose} || 0, 2);

    my $log_level = 2 - $verbose;      # Defaults to 'notice'
    $log_level = 4 if $options{quiet}; # Only 'error' or higher

    return $log_class->new( min_level => $log_level,
                            color     => $colors,
                            stderr    => 1,
                            newline   => 1 );
}

#------------------------------------------------------------------------------

sub log_colors {
    my ($self) = @_;

    # TODO: Create command line options for controlling colors and
    # process them here.

    return $self->default_log_colors;
}

#------------------------------------------------------------------------------

sub default_log_colors { return $PINTO_DEFAULT_LOG_COLORS }

#------------------------------------------------------------------------------

sub pinto_class { return 'Pinto' }

#------------------------------------------------------------------------------

1;

__END__
