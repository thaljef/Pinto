package Pinto::Action::Add;

# ABSTRACT: Add one distribution to the repository

use Moose;
use MooseX::Types::Moose qw(Bool);

use Path::Class;

use Pinto::Util;
use Pinto::Types qw(File);
use Pinto::PackageExtractor;
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
    isa      => File,
    required => 1,
    coerce   => 1,
);


has norecurse => (
   is      => 'ro',
   isa     => Bool,
   default => 0,
);


has extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy_build => 1,
);


#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Authorable
         Pinto::Role::FileFetcher
         Pinto::Role::PackageImporter
);

#------------------------------------------------------------------------------
# Builders

sub _build_extractor {
    my ($self) = @_;

    return Pinto::PackageExtractor->new( config => $self->config(),
                                         logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Public methods

override execute => sub {
    my ($self) = @_;

    my $archive = $self->archive();
    my $author  = $self->author();

    throw_error "Archive $archive does not exist"  if not -e $archive;
    throw_error "Archive $archive is not readable" if not -r $archive;

    my $root_dir   = $self->config->root_dir();
    my $basename   = $archive->basename();
    my $author_dir = Pinto::Util::author_dir($author);
    my $path       = $author_dir->file($basename)->as_foreign('Unix')->stringify();

    my $where    = {path => $path};
    my $existing = $self->repos->select_distributions( $where )->single();
    throw_error "Distribution $path already exists" if $existing;

    my $destination = $self->repos->root_dir->file( qw(authors id), $author_dir, $basename );
    $self->fetch(from => $archive, to => $destination);

    my @pkg_specs = $self->_extract_packages_and_check_authorship();
    $self->info(sprintf "Adding distribution $path with %d packages", scalar @pkg_specs);

    my $struct = { path     => $path,
                   source   => 'LOCAL',
                   mtime    => Pinto::Util::mtime($archive),
                   packages => \@pkg_specs };

    my $dist = $self->repos->add_distribution($struct);
    $self->add_message( Pinto::Util::added_dist_message($dist) );

    unless ( $self->norecurse() ) {
        my @imported = $self->import_prerequisites($archive);
        $self->add_message( Pinto::Util::imported_prereq_dist_message($_) ) for @imported;
    }

    return 1;
};

#------------------------------------------------------------------------------

sub _extract_packages_and_check_authorship {
    my ($self) = @_;

    my $archive = $self->archive();
    my $author  = $self->author();

    my @pkg_specs = $self->extractor->provides( archive => $archive );

    for my $pkg (@pkg_specs) {
        my $attrs = { prefetch => 'distribution' };
        my $where = { name => $pkg->{name}, 'distribution.source' => 'LOCAL'};
        my $incumbent = $self->repos->select_packages($where, $attrs)->first() or next;
        if ( (my $incumbent_author = $incumbent->distribution->author()) ne $author ) {
            throw_error "Only author $incumbent_author can update package $pkg->{name}";
        }
    }

    return @pkg_specs;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
