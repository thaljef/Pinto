# ABSTRACT: Specifies a package by name and version

package Pinto::PackageSpec;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(Str);

use Module::CoreList;
use English qw(-no_match_vars);

use Pinto::Types qw(Version);
use Pinto::Util qw(throw);

use version;
use overload ('""' => 'to_string');

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has version => (
    is      => 'ro',
    isa     => Version,
    coerce  => 1,
    default => sub { version->parse(0) }
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my @args = @_;
    if (@args == 1 and not ref $args[0]) {
        my ($name, $version) = split m{~}x, $_[0], 2;
        @args = (name => $name, version => $version || 0);
    }

    return $class->$orig(@args);
};

#------------------------------------------------------------------------------

=method is_core

=method is_core(in => $version)

Returns true if this package is satisfied by the perl core as-of a particular
version.  If the version is not specified, it defaults to whatever version
you are using now.

=cut

sub is_core {
    my ($self, %args) = @_;

    ## no critic qw(PackageVar);

    my $pv = version->parse($args{in}) || $PERL_VERSION;
    my $core_modules = $Module::CoreList::version{ $pv->numify + 0 };

    throw "Invalid perl version $pv" if not $core_modules;

    return 0 if not exists $core_modules->{$self->name};

    # on some perls, we'll get an 'uninitialized' warning when
    # the $core_version is undef.  So force to zero in that case
    my $core_version = $core_modules->{$self->name} || 0;

    return 0 if $self->version > $core_version;
    return 1;
}

#-------------------------------------------------------------------------------

=method is_perl()

Returns true if this package is perl itself.

=cut

sub is_perl {
    my ($self) = @_;

    return $self->name eq 'perl' ? 1 : 0;
}

#-------------------------------------------------------------------------------

=method to_string()

Serializes this PackageSpec to its string form.  This method is called
whenever the PackageSpec is evaluated in string context.

=cut

sub to_string {
    my ($self) = @_;
    return sprintf '%s~%s', $self->name, $self->version->stringify;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

