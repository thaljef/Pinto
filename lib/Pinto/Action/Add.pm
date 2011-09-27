package Pinto::Action::Add;

# ABSTRACT: Add one local distribution to the repository

use Moose;

use Try::Tiny;
use Path::Class;
use File::Temp;
use Dist::Metadata 0.920; # supports .zip

use Pinto::Util;
use Pinto::Types 0.017 qw(StrOrFileOrURI);

use Pinto::Exceptions qw(throw_error);


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

    throw_error "Archive $archive does not exist"  if not -e $archive;
    throw_error "Archive $archive is not readable" if not -r $archive;

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

    my $existing = $self->db->get_distribution_with_path($path);
    throw_error "Distribution $path already exists" if $existing;

    my @package_specs = $self->_extract_packages($archive);
    throw_error "$archive contains no packages" if not @package_specs;

    for my $pkg (@package_specs) {
        my $where = { name => $pkg->{name}, 'distribution.origin' => 'LOCAL'};
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $self->author() ) {
            throw_error "Only author $author can update package $pkg->{name}";
        }
    }

    my $pkg_count = @package_specs;
    $self->info("Adding distribution $path providing $pkg_count packages");

    my $dist = $self->db->new_distribution(path => $path);
    $self->db->add_distribution($dist);

    for my $pkg_spec ( @package_specs ) {
        my $pkg = $self->db->new_package(%{$pkg_spec}, distribution => $dist);
        $self->db->add_package($pkg);
    }

    return $dist;
  }

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, $archive) = @_;

    my $file = $archive->stringify();
    my $provides;

    try   { $provides = Dist::Metadata->new(file => $file)->package_versions(); }
    catch { throw_error "Unable to extract packages from $file: $_" };

    return map { {name => $_, version => $provides->{$_}} } keys %{ $provides }
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
