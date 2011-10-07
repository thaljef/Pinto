package Pinto::Action::Add;

# ABSTRACT: Add one local distribution to the repository

use Moose;

use Path::Class;

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
         Pinto::Role::Authored
         Pinto::Role::Extractor );

#------------------------------------------------------------------------------
# Public methods

override execute => sub {
    my ($self) = @_;

    my $repos   = $self->config->repos();
    my $archive = $self->archive();

    $archive = Pinto::Util::is_url($archive) ?
        $self->fetch_temporary(url => $archive) : file($archive);

    throw_error "Archive $archive does not exist"  if not -e $archive;
    throw_error "Archive $archive is not readable" if not -r $archive;

    my $dist = $self->_process_archive($archive);
    $self->store->add_archive( $archive => $dist->archive($repos) );
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

    my @package_specs = $self->extractor->extract_packages(archive => $archive);
    $self->whine("$archive contains no packages") if not @package_specs;

    for my $pkg (@package_specs) {
        my $where = { name => $pkg->{name}, 'distribution.source' => 'LOCAL'};
        my $incumbent = $self->db->get_all_packages($where)->first() or next;
        if ( (my $author = $incumbent->author() ) ne $self->author() ) {
            throw_error "Only author $author can update package $pkg->{name}";
        }
    }

    my $pkg_count = @package_specs;
    $self->info("Adding distribution $path providing $pkg_count packages");

    my $dist = $self->db->new_distribution(path => $path);
    my @packages = map { $self->db->new_package(%{$_}) } @package_specs;

    return $self->db->add_distribution_with_packages($dist, @packages);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
