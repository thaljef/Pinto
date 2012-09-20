# ABSTRACT: Extract packages provided/required by a distribution archive

package Pinto::PackageExtractor;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Try::Tiny;
use Dist::Requires;
use Dist::Metadata;

use Pinto::Exception qw(throw);

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

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

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

    $self->info("Extracting packages from archive $archive");

    my $provides =   try { Dist::Metadata->new(file => $archive)->package_versions }
                   catch { throw "Unable to extract packages from $archive: $_"    };

    my @provides;
    for my $pkg_name ( sort keys %{ $provides } ) {
        my $pkg_ver = version->parse( $provides->{$pkg_name} );
        $self->debug("Archive $archive provides: $pkg_name-$pkg_ver");
        push @provides, {name => $pkg_name, version => $pkg_ver};
    }

    @provides = $self->__common_sense_workaround($args{archive}->basename)
      if @provides == 0 and $args{archive}->basename =~ m/^ common-sense /x;

    $self->warning("$archive provides no packages") if not @provides;

    return $self->_versionize(@provides);
}

#-----------------------------------------------------------------------------
# NB: Likewise, Dist::Requires uses Module::Build and MakeMaker to
# discover the prerequisites.  And they might be doing weird stuff to
# the version numbers when they try to produce a valid MYMETA files.

sub requires {
    my ($self, %args) = @_;

    my $archive = $args{archive};

    $self->info("Extracting prerequisites from archive $archive");

    my %prereqs =   try { Dist::Requires->new()->prerequisites(dist => $archive)    }
                  catch { throw "Unable to extract prerequisites from $archive: $_" };

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
            $self->warning("Package $vname has invalid version. Ignoring it");
        }
        else {
            throw "Package $vname has invalid version: $@";
        }
    }

    return @versionized;
}

#-----------------------------------------------------------------------------
# HACK: The common-sense distribution generates the .pm file at build time.
# It relies on an unusual feature of PAUSE that scans the __DATA__ section
# of .PM files for potential packages.  Module::Metdata doesn't have that
# feature, so to us, it appears that common-sense contains no packages.
# I've asked the author to use the "provides" field of the META file so
# that other tools can discover the packages in his distribution, but
# he has refused to do so.  So we work around it by just assuming the
# distribution contains a package named "common::sense".

sub __common_sense_workaround {
    my ($self, $cs_archive) = @_;

    my ($version) = ($cs_archive =~ m/common-sense- ([\d_.]+) \.tar\.gz/x);

    return { name => 'common::sense',
             version => version->parse($version) };
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__
