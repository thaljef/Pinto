package Pinto::PackageExtractor;

# ABSTRACT: Extract packages provided/required by a distribution archive

use Moose;
use MooseX::Types::Moose qw(Bool);

use Try::Tiny;
use Dist::Requires 0.004;  # Bug fixes
use Dist::Metadata 0.922;  # Supports zip

use Pinto::Exceptions qw(throw_error);

use version;
use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Attributes

has lax => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#-----------------------------------------------------------------------------
# NB: Dist::Metadata uses CPAN::Meta, which silently normalizes all
# invalid or undefined version numbers to zero.  I think I would
# prefer if it just reported them as they are, and let me decide what
# to do about the invalid ones.  At least, that was the idea with the
# lax() option.  But I'm not sure it makes sense.

sub provides {
    my ($self, %args) = @_;

    # Must stringify, cuz D::M doesn't like Path::Class objects
    my $archive = $args{archive}->stringify();

    $self->debug("Extracting packages from archive $archive");

    my $provides =   try { Dist::Metadata->new(file => $archive)->package_versions()  }
                   catch { throw_error "Unable to extract packages from $archive: $_" };

    my @provides;
    for my $pkg_name ( sort keys %{ $provides } ) {
        my $pkg_ver = version->parse( $provides->{$pkg_name} );
        $self->debug("Archive $archive provides: $pkg_name-$pkg_ver");
        push @provides, {name => $pkg_name, version => $pkg_ver};
    }

    $self->whine("$archive contains no packages") if not @provides;

    return $self->_versionize(@provides);
}

#-----------------------------------------------------------------------------
# NB: Likewise, Dist::Requires uses Module::Build and MakeMaker to
# discover the prerequisites.  And they might be doing weird stuff to
# the version numbers when they try to produce a valid MYMETA files.

sub requires {
    my ($self, %args) = @_;

    my $archive = $args{archive};

    $self->debug("Extracting prerequisites from $archive");

    my %prereqs =   try { Dist::Requires->new()->prerequisites(dist => $archive)          }
                  catch { throw_error "Unable to extract prerequisites from $archive: $_" };

    my @prereqs;
    for my $pkg_name ( sort keys %prereqs ) {
        my $pkg_ver = version->parse( $prereqs{$pkg_name} );
        $self->debug("Archive $archive requires: $pkg_name-$pkg_ver");
        push @prereqs, {name => $pkg_name, version => $pkg_ver};
    }

    return $self->_versionize(@prereqs);
}

#-----------------------------------------------------------------------------

sub _versionize {
    my ($self, @pkg_specs) = @_;

    my @versionized;
    for my $pkg_spec_ref (@pkg_specs) {

        my %pkg_spec = %{ $pkg_spec_ref };  # Making a copy
        my $vname    = "$pkg_spec{name}-$pkg_spec{version}";
        my $version  = eval { version->parse($pkg_spec{version}) };

        if ( defined $version ) {
            $pkg_spec{version} = $version;
            push @versionized, \%pkg_spec;
        }
        elsif ( $self->lax() ) {
            $self->whine("Package $vname has invalid version. Ignoring it");
        }
        else {
            throw_error "Package $vname has invalid version: $@";
        }
    }

    return @versionized;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
