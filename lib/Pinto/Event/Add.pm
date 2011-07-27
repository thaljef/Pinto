package Pinto::Event::Add;

# ABSTRACT: An event to add one archive to the repository

use Moose;

use Carp;
use File::Copy;
use Dist::MetaData;

use Pinto::Util;
use Pinto::IndexManager;

extends 'Pinto::Event';

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

sub prepare {
    my ($self) = @_;

    my $file = $self->file();
    croak "$file does not exist" if not -e $file;
    croak "$file is not readable" if not -r $file;
}

#------------------------------------------------------------------------------
# TODO: Refactor this. Consider checking authorship in the prepare() stage

sub execute {
    my ($self) = @_;

    my $local  = $self->config()->get_required('local');
    my $author = $self->config()->get_required('author');
    my $file   = $self->file();

    my $idx_mgr = Pinto::IndexManager->instance();
    if ( my $file_in_index = $idx_mgr->has_local_file(author => $author, file => $file) ) {
        croak "File $file already exists in the local index as $file_in_index";
    }

    # Dist::Metadata will croak for us if $file is whack!
    my $distmeta = Dist::Metadata->new(file => $file->stringify());
    my $provides = $distmeta->package_versions();
    return if not %{ $provides };


    my @conflicts = ();
    for my $package_name (keys %{ $provides }) {
        if ( my $orig_author = $idx_mgr->local_author_of(package => $package_name) ) {
            push @conflicts, "Package $package_name is already owned by $orig_author\n"
                if $orig_author ne $author;
        }
    }
    die @conflicts if @conflicts;

    while( my ($package_name, $version) = each %{ $provides } ) {
        $self->logger->log("Adding $package_name $version");
        $idx_mgr->add_local_package(name  => $package_name,
            version => $version, author => $author, file => $file);
    }


    my $destination_dir = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    $destination_dir->mkpath();  #TODO: log & error check
    copy($file, $destination_dir); #TODO: log & error check

    my $base = $file->basename();
    my $message = "Added $base providing:\n    ";
    $message .= join "\n    ", sort keys %{ $provides };
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
