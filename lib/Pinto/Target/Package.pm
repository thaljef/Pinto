# ABSTRACT: Specifies a package by name and version

package Pinto::Target::Package;

use Moose;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use Try::Tiny;
use Module::CoreList;
use CPAN::Meta::Requirements;

use Pinto::Util qw(throw trim_text);

use version;
use overload ( '""' => 'to_string');

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
    isa     => Str,
    default => '0',
);

has _vreq => (
    is       => 'ro',
    isa      => 'CPAN::Meta::Requirements',
    writer   => '_set_vreq',
    init_arg => undef,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my @args = @_;

    if ( @args == 1 and not ref $args[0] ) {
        my ( $name, $version ) = $_[0] =~ m{^ ([A-Z0-9_:]+) (?:~)? (.*)}ix;
        $version =~ s/^\@/==/; # Allow "@" to be used as a synonym for "=="
        @args = ( name => $name, version => trim_text($version) || 0 );
    }

    return $class->$orig(@args);
};

#------------------------------------------------------------------------------

sub BUILD {
    my $self = shift;

    # We want to construct the C::M::Requirements object right away to ensure
    # $self->version is a valid string.  But if we do this in a builder, it 
    # has to be lazy because it depends on other attributes. So instead, we
    # construct it during the BUILD and use a private writer to set it.

    my $args = {$self->name => $self->version};

    my $req = try   { CPAN::Meta::Requirements->from_string_hash( $args) }
              catch { throw "Invalid package target ($self): $_"      };

    $self->_set_vreq($req);
    return $self;
}

#------------------------------------------------------------------------------

=method is_core

=method is_core(in => $version)

Returns true if this Target is satisfied by the perl core as-of a particular
version.  If the version is not specified, it defaults to whatever version you
are using now.

=cut

sub is_core {
    my ( $self, %args ) = @_;

    ## no critic qw(PackageVar);

    # Note: $PERL_VERSION is broken on old perls, so we must make
    # our own version object from the old $] variable

    my $pv = version->parse( $args{in} ) || version->parse($]);
    my $core_modules = $Module::CoreList::version{ $pv->numify + 0 };

    throw "Invalid perl version $pv" if not $core_modules;

    return 0 if not exists $core_modules->{ $self->name };

    # on some perls, we'll get an 'uninitialized' warning when
    # the $core_version is undef.  So force to zero in that case
    my $core_version = $core_modules->{ $self->name } || 0;

    return 1 if $self->is_satisfied_by( $core_version );
    return 0;
}

#-------------------------------------------------------------------------------

=method is_perl()

Returns true if this Target is a perl version of perl itself.

=cut

sub is_perl {
    my ($self) = @_;

    return !! $self->name eq 'perl';
}

#-------------------------------------------------------------------------------

=method is_satisfied_by($version)

Returns true if this Target is satisfied by version C<$version> of the package.

=cut

sub is_satisfied_by {
    my ($self, $version) = @_;

    return !! $self->_vreq->accepts_module($self->name => $version);
}

#-------------------------------------------------------------------------------

=method to_string()

Serializes this Target to its string form.  This method is called whenever the
Target is evaluated in string context.

=cut

sub to_string {
    my ($self) = @_;
    my $format = $self->version =~ m/^ [=<>!\@] /x ? '%s%s' : '%s~%s';
    return sprintf $format, $self->name, $self->version;
}

#------------------------------------------------------------------------------
# XXX Are we using this?

sub gte {
    my ($self, $other, $flip) = @_;
    return $self->is_satisfied_by($other) if not $flip;
    return $other->is_satisfied_by($self) if $flip;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

