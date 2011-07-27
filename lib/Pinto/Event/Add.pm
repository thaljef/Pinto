package Pinto::Event::Add;

# ABSTRACT: An event to add one archive to the repository

use Moose;

use Carp;
use File::Copy;
use Dist::MetaData;

use Pinto::Util;

extends 'Pinto::Event';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has author => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has file => (
    is       => 'ro',
    isa      => 'Path::Class::File',
    required => 1,
);

#------------------------------------------------------------------------------

sub prepare {
    my ($self) = @_;

    my $file = $self->file();
    croak "$file does not exist" if not -e $file;
    croak "$file is not readable" if not -r $file;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $local  = $self->local();
    my $author = $self->author();
    my $file   = $self->file();

    my $author_dir    = Pinto::Util::directory_for_author($author);
    my $file_in_index = file($author_dir, $file->basename())->as_foreign('Unix');

    if (my $existing_file = $self->local_index()->packages_by_file->{$file_in_index}) {
        croak "File $file_in_index already exists in the local index";
    }

    # Dist::Metadata will croak for us if $file is whack!
    my $distmeta = Dist::Metadata->new(file => $file);
    my $provides = $distmeta->package_versions();
    return if not %{ $provides };


    my @conflicts = ();
    for my $package_name (keys %{ $provides }) {
        if ( my $incumbent_package = $self->local_index()->packages_by_name()->{$package_name} ) {
            my $incumbent_author = $incumbent_package->author();
            push @conflicts, "Package $package_name is already owned by $incumbent_author\n"
                if $incumbent_author ne $author;
        }
    }
    die @conflicts if @conflicts;


    my @packages = ();
    while( my ($package_name, $version) = each %{ $provides } ) {
        $self->log->info("Adding $package_name $version");
        push @packages, Pinto::Package->new(name => $package_name,
                                            version => $version,
                                            file => "$file_in_index");
    }

    $self->local_index->add(@packages);

    my $destination_dir = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    $destination_dir->mkpath();  #TODO: log & error check
    copy($file, $destination_dir); #TODO: log & error check

    my $message = "Added local archive $file_in_index containing packages:\n\n";
    $message .= join "\n", sort map {$_->name()} @packages;
    $self->_set_message($message);

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
