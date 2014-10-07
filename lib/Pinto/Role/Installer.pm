# ABSTRACT: Something that installs packages

package Pinto::Role::Installer;

use Moose::Role;
use MooseX::Types::Moose qw(Str HashRef Maybe);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Path::Class qw(dir);
use File::Which qw(which);

use Pinto::Util qw(throw mask_uri_passwords);
use Pinto::Constants qw($PINTO_MINIMUM_CPANM_VERSION);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has cpanm_options => (
    is  => 'ro',
    isa => HashRef [ Maybe [Str] ],
    default => sub { {} },
    lazy    => 1,
);

has cpanm_exe => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_cpanm_exe',
    lazy    => 1,
);

#-----------------------------------------------------------------------------

requires qw( execute targets mirror_uri );

#-----------------------------------------------------------------------------

with qw( Pinto::Role::Plated );

#-----------------------------------------------------------------------------

sub _build_cpanm_exe {
    my ($self) = @_;

    return dir( $ENV{PINTO_HOME} )->subdir('sbin')->file('cpanm')->stringify
        if $ENV{PINTO_HOME};

    my $cpanm_exe = which('cpanm')
        or throw 'Could not find cpanm in PATH';

    my $cpanm_version_cmd        = "$cpanm_exe --version";
    my $cpanm_version_cmd_output = qx{$cpanm_version_cmd};    ## no critic qw(Backtick)
    throw "Could not learn version of cpanm: $!" if $?;

    my ($cpanm_version) = $cpanm_version_cmd_output =~ m{version ([\d.]+)}
        or throw "Could not parse cpanm version number from $cpanm_version_cmd_output";

    if ( $cpanm_version < $PINTO_MINIMUM_CPANM_VERSION ) {
        throw "Your cpanm ($cpanm_version) is too old.  Must have $PINTO_MINIMUM_CPANM_VERSION or newer";
    }

    return $cpanm_exe;
}

#-----------------------------------------------------------------------------

after execute => sub {
    my ($self) = @_;

    # Wire cpanm to our repo
    my $opts = $self->cpanm_options;
    $opts->{mirror} = $self->mirror_uri;
    $opts->{'mirror-only'} = '';

    # Process other cpanm options
    my @cpanm_opts;
    for my $opt ( keys %{$opts} ) {
        my $dashes     = ( length $opt == 1 ) ? '-' : '--';
        my $dashed_opt = $dashes . $opt;
        my $opt_value  = $opts->{$opt};
        push @cpanm_opts, $dashed_opt;
        push @cpanm_opts, $opt_value if defined $opt_value && length $opt_value;
    }

    # Scrub passwords from the command so they don't appear in the logs
    my @sanitized_cpanm_opts = map { mask_uri_passwords($_) } @cpanm_opts;
    $self->info( join ' ', 'Running:', $self->cpanm_exe, @sanitized_cpanm_opts );

    # Run cpanm
    0 == system( $self->cpanm_exe, @cpanm_opts, $self->targets )
        or throw "Installation failed.  See the cpanm build log for details";
};

#-----------------------------------------------------------------------------
1;

__END__
