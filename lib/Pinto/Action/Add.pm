package Pinto::Action::Add;

# ABSTRACT: An action to add one local distribution to the repository

use Moose;

use Try::Tiny;
use Path::Class;
use File::Temp;
use Dist::Metadata 0.920; # supports .zip

use Pinto::Util;
use Pinto::Types 0.017 qw(StrOrFileOrURI);

use Pinto::Exceptions qw(throw_io throw_empty_dist throw_dist_parse
                         throw_dupe throw_unauthorized);

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

    my $repos   = $self->config->repos();
    my $archive = $self->archive();

    $archive = Pinto::Util::is_url($archive) ?
        $self->fetch_temporary(url => $archive) : file($archive);

    throw_io "Archive $archive does not exist"  if not -e $archive;
    throw_io "Archive $archive is not readable" if not -r $archive;

    my $dist = $self->_process_archive($archive);
    $self->store->add(file => $dist->physical_path($repos), source => $archive);
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

    $self->db->get_distribution_with_path($path)
      and throw_dupe "Distribution $path already exists";

    for my $pkg (@packages) {
        my $name = $pkg->{name};
        my $where = { is_local => 1, name => $name };
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $self->author() ) {
            throw_unauthorized "Only author $author can update $name";
        }
    }

    $self->info(sprintf "Adding $path with %i packages", scalar @packages);
    my $dist = $self->db->add_distribution( {path => $path, origin => 'LOCAL'} );

    for my $pkg ( @packages ) {
        $pkg->{distribution} = $dist->id();
        $self->db->add_package( $pkg );
    }

    return $dist;
  }

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, $archive) = @_;

    my $provides;

    try {
        my $distmeta = Dist::Metadata->new(file => $archive->stringify());
        $provides = $distmeta->package_versions();
    }
    catch {
        throw_dist_parse "Unable to extract packages from $archive: $_";
    };

    throw_empty_dist "$archive contains no packages" if not %{ $provides };

    my @packages = ();
    for my $name (sort keys %{ $provides }) {
        my $version = $provides->{$name} || 'undef';
        push @packages, { name            => $name,
                          version         => $version,
                          is_local        => 1 };
    }

    return @packages;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
