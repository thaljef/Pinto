package Pinto::Action::Add;

# ABSTRACT: An action to add one local distribution to the repository

use Moose;

use Path::Class;
use File::Temp;
use Dist::Metadata 0.920; # supports .zip

use Pinto::Util;
use Pinto::Types 0.017 qw(StrOrFileOrURI);
use Pinto::Exception::IO qw(throw_io);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Attrbutes

has archive => (
    is       => 'ro',
    isa      => StrOrFileOrURI,
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::UserAgent
         Pinto::Role::Authored );

#------------------------------------------------------------------------------

override execute => sub {
    my ($self) = @_;

    my $repos     = $self->config->repos();
    my $archive   = $self->archive();

    $archive = _is_url($archive) ? $self->_dist_from_url($archive) : file($archive);
    my $dist = $self->_add_to_schema($archive);

    $self->store->add( file => $dist->path($repos), source => $archive );
    $self->add_message( Pinto::Util::added_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

sub _add_to_schema {
    my ($self, $archive) = @_;

    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($self->author());
    my $location   = $author_dir->file($basename)->as_foreign('Unix');
    my @packages   = $self->_extract_packages($archive);

    $self->logger->info(sprintf "Adding $location with %i packages", scalar @packages);

    # Create new dist
    my $dist = $self->db->schema->resultset('Distribution')->create(
        { location => $location, origin => 'LOCAL'} );

    # Create new packages
    for my $pkg ( @packages ) {
      my $version_numeric = version->parse($pkg->{version})->numify();
      $self->db->schema->resultset('Package')->create(
          { %{ $pkg }, version_numeric => $version_numeric, distribution => $dist->id() } );
    }

    return $dist;
  }

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, $archive) = @_;

    my $distmeta = Dist::Metadata->new(file => $archive->stringify());
    my $provides = $distmeta->package_versions();
    throw_io "$archive contains no packages" if not %{ $provides };

    my @packages = ();
    for my $package_name (sort keys %{ $provides }) {
        my $version = $provides->{$package_name} || 'undef';
        push @packages, { name => $package_name, version => $version };
    }

    return @packages;
}

#------------------------------------------------------------------------------

sub _is_url {
    my ($it) = @_;

    return 1 if eval { $it->isa('URI') };
    return 0 if eval { $it->isa('Path::Class::File') };
    return $it =~ m/^ (?: http|ftp|file|) : /x;
}

#------------------------------------------------------------------------------

sub _dist_from_url {
    my ($self, $dist_url) = @_;

    my $url = URI->new($dist_url)->canonical();
    my $path = Path::Class::file( $url->path() );
    return $path if $url->scheme() eq 'file';

    my $base     = $path->basename();
    my $tempdir  = File::Temp::tempdir(CLEANUP => 1);
    my $tempfile = Path::Class::file($tempdir, $base);

    $self->fetch(url => $url, to => $tempfile);

    return Path::Class::file($tempfile);
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
