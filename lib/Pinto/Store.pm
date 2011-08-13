package Pinto::Store;

# ABSTRACT: Back-end storage for a Pinto repository

use Moose;

use Carp;
use File::Copy;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

# TODO: Do we really need three different lists of paths, or can we just have
# one that represents all the paths that need to be committed?

has added_paths => (
    is          => 'ro',
    isa         => 'ArrayRef[Path::Class]',
    init_arg    => undef,
    default     => sub { [] },
);

has removed_paths => (
    is          => 'ro',
    isa         => 'ArrayRef[Path::Class]',
    init_arg    => undef,
    default     => sub { [] },
);

has modified_paths => (
    is          => 'ro',
    isa         => 'ArrayRef[Path::Class]',
    init_arg    => undef,
    default     => sub { [] },
);

#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

with qw( Pinto::Role::PathMaker );

#------------------------------------------------------------------------------
# Methods

=method initialize()

This method is called before each batch of Pinto events, and is
responsible for doing any setup work that is required by the Store.
This could include making a directory on the file system, checking out
or updating a working copy, cloning, or pulling commits.  If the
initialization fails, an exception should be thrown.

The default implementation simply creates a directory.

=cut

sub initialize {
    my ($self) = @_;

    my $local = $self->config->local();
    $self->mkpath($local);

    return 1;
}

#------------------------------------------------------------------------------

=method is_initialized()

Returns true if the store appears to be initialized.  In this base
class, it simply means that the working directory exists.  For other
derived classes, this could mean that the working copy is up-to-date.

=cut

sub is_initialized {
    my ($self) = @_;

    return -e $self->config->local();
}

#------------------------------------------------------------------------------

=method finalize(message => 'what happened')

This method is called after each batch of Pinto events and is
responsible for doing any work that is required to commit the Store.
This could include scheduling files for addition/deletion, pushing
commits to a remote repository, and/or making a tag.  If the
finalization fails, an exception should be thrown.

=cut

sub finalize {
    my ($self, %args) = @_;
    return 1;
}


#------------------------------------------------------------------------------

=method add( file => $some_file, source => $other_file )

Adds the specified C<file> (as a L<Path::Class::File>) to this Store.
The path to C<file> is presumed to be somewhere beneath the root
directory of this Store.  If the optional C<source> is given (as a
L<Path::Class::File>), then that C<source> is first copied to C<file>.
If C<source> is not specified, then the C<file> must already exist.
Returns a reference to this Store.

=cut

sub add {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $source = $args{source};

    croak "$file does not exist and no source was specified"
        if not -e $file and not defined $source;

    croak "$source is not a file"
        if $source and $source->is_dir();

    if ($source) {

        if ( not -e (my $parent = $file->parent()) ) {
          $self->mkpath($parent);
        }

        $self->logger->debug("Copying $source to $file");

        File::Copy::copy($source, $file)
            or croak "Failed to copy $source to $file: $!";
    }

    return $self;
}

#------------------------------------------------------------------------------

=method remove( file => $some_file, prune => 1 );

Removes the specified C<file> (as a L<Path::Class::File>) from this
Store.  The path to C<file> is presumed to be somewhere beneath the
root directory of this Store.  If C<prune> is true, then any empty
directories above C<file> will also be removed.  Returns a reference
to this Store.

=cut

sub remove {
    my ($self, %args) = @_;

    my $path  = $args{file};
    my $prune = $args{prune};  # TODO: prune=1 should be the default

    return $self if not -e $path;
    croak "$path is not a file" if $path->is_dir();

    $self->logger->info("Removing file $path");
    $path->remove() or croak "Failed to remove $path: $!";

    if ($prune) {
        while (my $dir = $path->dir()) {
            last if $dir->children();
            $self->logger->debug("Removing empty directory $dir");
            $dir->remove();
            $path = $dir;
        }
    }

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

L<Pinto::Store> is the default back-end for a Pinto repository.  It
basically just represents files on disk.  You should look at
L<Pinto::Store::Svn> or L<Pinto::Store::Git> for a more interesting
example.

=cut
