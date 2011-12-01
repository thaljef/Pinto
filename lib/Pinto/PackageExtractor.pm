package Pinto::PackageExtractor;

# ABSTRACT: Extract packages provided/required by a distribution archive

use Moose;

use Try::Tiny;
use Dist::Requires;
use Dist::Metadata 0.922;

use Pinto::Exceptions qw(throw_error);

use version;
use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#-----------------------------------------------------------------------------

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
    return @provides;
}

#-----------------------------------------------------------------------------

sub requires {
    my ($self, %args) = @_;

    my $archive = $args{archive};
    $self->debug("Extracting prerequisites from $archive");

    my %prereqs =   try { Dist::Requires->new()->requires(dist => $archive)               }
                  catch { throw_error "Unable to extract prerequisites from $archive: $_" };

    my @prereqs;
    for my $pkg_name ( sort keys %prereqs ) {
        my $pkg_ver = version->parse( $prereqs{$pkg_name} );
        $self->debug("Archive $archive requires: $pkg_name-$pkg_ver");
        push @prereqs, {name => $pkg_name, version => $pkg_ver};
    }

    return @prereqs;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__
