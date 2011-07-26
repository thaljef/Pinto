package Pinto::Config;

# ABSTRACT: User configuration for Pinto

use Moose;

use Carp;
use Config::Tiny;
use File::HomeDir;
use Path::Class;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

=attr profile

Returns the path to your L<Pinto> configuration file.  If you do not
specify one through the constructor, then we look at C<$ENV{PINTO}>,
then F<~/.pinto/config.ini>.  If the config file does not exist in any
of those locations, then you will get an empty config.

=cut

has 'profile' => (
    is           => 'ro',
    isa          => 'Str',
);

#------------------------------------------------------------------------------

=for Pod::Coverage BUILD

Internal, not documented

=cut

sub BUILD {
    my ($self, $args) = @_;

    # TODO: Rewrite all this.  It sucks!
    # TODO: Decide where to do configuration validation

    my $profile = $self->profile() || _find_profile();
    croak "$profile does not exist" if defined $profile and not -e $profile;

    my $params = $profile ? Config::Tiny->read( $profile )->{_} : {};

    croak "Failed to read profile $profile: " . Config::Tiny->errorstr()
        if not $params;

    $self->{$_} = $params->{$_} for keys %{ $params };
    $self->{$_} = $args->{$_}   for keys %{ $args   };

    return $self;
}

#------------------------------------------------------------------------------

=method get_required($key)

Returns the configuration value assocated with the given C<$key>.  If
that value is not defined, then an exception is thrown.

=cut

sub get_required {
    my ($self, $key) = @_;

    croak 'Must specify a configuration key'
        if not $key;

    die "Parameter '$key' is required in your configuration.\n"
        if not exists $self->{$key};

    return $self->{$key};
}

#------------------------------------------------------------------------------

=method get($key)

Returns the configuration value associated with the given C<$key>.  The
value may be undefined.

=cut

sub get {
    my ($self, $key) = @_;

    croak 'Must specify a configuration key'
        if not $key;

    return $self->{$key};
}

#------------------------------------------------------------------------------

sub _find_profile {
    return $ENV{PERL_PINTO} if defined $ENV{PERL_PINTO};
    my $home_file = file(File::HomeDir->my_home(), 'pinto', 'config.ini');
    return $home_file if -e $home_file;
    return;
}

#------------------------------------------------------------------------------

1;

__END__
