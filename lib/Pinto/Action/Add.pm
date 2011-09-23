package Pinto::Action::Add;

# ABSTRACT: Add one local distribution to the repository

use Moose;

use Path::Class;
use File::Temp;
use Dist::Metadata 0.920; # supports .zip

use Pinto::Util;
use Pinto::Types 0.017 qw(StrOrFileOrURI);

use Pinto::Exceptions qw(throw_error);
use Exception::Class::TryCatch;

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

    my @packages = $self->_extract_packages($archive);
    throw_error "$archive contains no packages" if not @packages;

    for my $pkg (@packages) {
        my $name = $pkg->{name};
        my $where = { is_local => 1, name => $name };
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $self->author() ) {
            throw_error "Only author $author can update package $name";
        }
    }

    my $pkg_count = @packages;
    $self->info("Adding distribution $path providing $pkg_count packages");
    my $dist = $self->db->add_distribution( {path => $path, is_local => 1} );
    $self->db->add_package( { %{$_}, distribution => $dist->id() } ) for @packages;

    return $dist;
  }

#------------------------------------------------------------------------------

sub _extract_packages {
    my ($self, $archive) = @_;

    my $provides = eval {
        my $distmeta = Dist::Metadata->new(file => $archive->stringify());
        $distmeta->package_versions();
    };

    throw_error "Unable to extract packages from $archive: $@" if $@;

    my @packages = ();
    while (my ($name, $version) = each %{ $provides }) {
        push @packages, { name => $name, version => $version };
    }

    return @packages;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
