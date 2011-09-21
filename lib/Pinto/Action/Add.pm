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
    throw_io "Archive $archive does not exist"  if not -e $archive;
    throw_io "Archive $archive is not readable" if not -r $archive;

    my $dist = $self->_process_archive($archive);
    $self->store->add( file => $dist->physical_path($repos), source => $archive );
    $self->add_message( Pinto::Util::added_dist_message($dist) );

    return 1;
};

#------------------------------------------------------------------------------

sub _process_archive {
    my ($self, $archive) = @_;

    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($self->author());
    my $path       = $author_dir->file($basename)->as_foreign('Unix');
    my @packages   = $self->_extract_packages($archive);

    if ( $self->db->get_distribution_with_path($path) ) {
        Pinto::Exception->throw("Distribution $path already exists");
    }

    for my $pkg (@packages) {
        my $name = $pkg->{name};
        my $where = { is_local => 1, name => $name };
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $self->author() ) {
            Pinto::Exception->throw("Only author $author can update $name");
        }
    }

    $self->logger->info(sprintf "Adding $path with %i packages", scalar @packages);
    my $dist = $self->db->add_distribution( { path => $path, origin => 'LOCAL'} );

    for my $pkg ( @packages ) {
        $pkg->{distribution} = $dist->id();
        $self->db->add_package( $pkg );
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
    for my $name (sort keys %{ $provides }) {
        my $version = $provides->{$name} || 'undef';
        push @packages, { name            => $name,
                          version         => $version,
                          is_local        => 1 };
    }

    return @packages;
}

#------------------------------------------------------------------------------

sub _is_url {
    my ($it) = @_;

    return 1 if eval { $it->isa('URI') };
    return 0 if eval { $it->isa('Path::Class::File') };
    return $it =~ m/^ (?: http|ftp|file) : /x;
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
