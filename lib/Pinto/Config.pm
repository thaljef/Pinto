package Pinto::Config;

# ABSTRACT: User configuration for Pinto

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class;

use URI;
use Carp;
use Config::Tiny;
use File::HomeDir;
use Path::Class;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose types (TOOD: Consider moving these out to another module)

class_type('URI');

coerce 'URI',
    from 'Str',   via { URI->new($_) };

subtype 'AuthorID',
    as 'Str',
    where { $_ !~ /\W/ },
    message { "The author ($_) can only be alphanumeric characters" };

coerce 'AuthorID',
    from 'Str',
    via  { uc $_ };

#------------------------------------------------------------------------------
# Moose attributes

=attr profile

Returns the path to your L<Pinto> configuration file.  If you do not
specify one through the constructor, then we look at C<$ENV{PINTO}>,
then F<~/.pinto/config.ini>.  If the config file does not exist in any
of those locations, then you will get an empty config.

=cut

has 'profile' => (
    is           => 'ro',
    isa          => 'Path::Class::File',
);


has 'local'   => (
    is        => 'ro',
    isa       => 'Path::Class::Dir',
    required  => 1,
    coerce    => 1,
);


has 'mirror'  => (
    is        => 'ro',
    isa       => 'URI',
    default   => sub { URI->new( 'http://cpan.perl.org' ) },
    coerce    => 1,
);


has 'author'  => (
    is        => 'rw',
    isa       => 'AuthorID',
    coerce    => 1,
);


has 'nocleanup' => (
    is        => 'ro',
    isa       => 'Bool',
    default   => 0,
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
    my $home_file = Path::Class::file(File::HomeDir->my_home(), '.pinto', 'config.ini');
    return $home_file if -e $home_file;
    return;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
