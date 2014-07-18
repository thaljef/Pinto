# ABSTRACT: Something that installs packages

package Pinto::Role::Installer;

use Moose::Role;
use MooseX::Types::Moose qw(Str HashRef Maybe);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Path::Class qw(dir);

use Pinto::Util qw(throw mask_uri_passwords find_cpanm_exe);
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
    return find_cpanm_exe();
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
