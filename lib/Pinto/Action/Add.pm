package Pinto::Action::Add;

# ABSTRACT: An action to add one archive to the repository

use Moose;

use Carp;
use File::Copy;
use Dist::MetaData;

use Pinto::Util;
use Pinto::IndexManager;

extends 'Pinto::Action';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attrbutes

has file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::Configurable Pinto::Role::Loggable);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local  = $self->config()->get_required('local');
    my $author = $self->config()->get_required('author');

    my $file   = $self->file();
    my $base   = $file->basename();

    # croak "$file does not exist" if not -e $file;
    # croak "$file is not readable" if not -r $file;

    my $idxmgr = $self->idxmgr();
    if ( my $existing = $idxmgr->find_file(author => $author, file => $file) ) {
        croak "Archive $base already exists as $existing";
    }

    # Dist::Metadata will croak for us if $file is whack!
    my $distmeta = Dist::Metadata->new(file => $file->stringify());
    my $provides = $distmeta->package_versions();
    return 0 if not %{ $provides };


    my @conflicts = ();
    for my $package_name (sort keys %{ $provides }) {
        if ( my $orig_author = $idxmgr->local_author_of(package => $package_name) ) {
            push @conflicts, "Package $package_name is already owned by $orig_author\n"
                if $orig_author ne $author;
        }
    }
    die @conflicts if @conflicts;

    for my $package_name (sort keys %{ $provides }) {
        my $version = $provides->{$package_name} || 'undef';
        $self->logger->log("Adding package $package_name $version");
        $idxmgr->add_local_package(name  => $package_name,
            version => $version, author => $author, file => $file);
    }

    my $destination_dir = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    $destination_dir->mkpath();    # TODO: log & error check
    copy($file, $destination_dir); # TODO: log & error check

    # TODO: Actions shouldn't care about when to write indexes.
    $idxmgr->rebuild_master_index()->write();
    $idxmgr->local_index()->write();

    my $message = Pinto::Util::format_message("Added archive $base providing:", sort keys %{$provides});
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
