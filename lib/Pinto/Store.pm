package Pinto::Store;

# ABSTRACT: Storage for a Pinto repository

use Moose;

use File::Copy;

use Pinto::Exceptions qw(throw_io throw_args);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable
         Pinto::Role::PathMaker );

#------------------------------------------------------------------------------
# Methods

=method initialize()

This method is called before each batch of Pinto events, and is
responsible for doing any setup work that is required by the Store.
This could include making a directory on the file system, checking out
or updating a working copy, cloning, or pulling commits.  If the
initialization fails, an exception should be thrown.  The default
implementation simply creates the repository directory, if it isn't
already there.  Returns a reference to this Store.

=cut

sub initialize {
    my ($self) = @_;

    $self->debug('Initializing the store');
    my $repos = $self->config->repos();
    $self->mkpath($repos);

    return $self;
}

#------------------------------------------------------------------------------

=method commit(message => 'what happened')

This method is called after each batch of Pinto events and is
responsible for doing any work that is required to commit the Store.
This could include scheduling files for addition/deletion, pushing
commits to a remote repository.  If the commit fails, an exception
should be thrown.  The default implementation merely logs the message.
Returns a reference to this Store.

=cut

sub commit {
    my ($self, %args) = @_;

    my $message = $args{message} || 'Committing the store';
    $self->debug($message);

    return $self;
}

#------------------------------------------------------------------------------

=method tag( tag => $tag_name )

Tags the store.  For some subclasses, this means performing some kind
of "tag" operations.  For others, it could mean doing a copy
operation.  The default implementation does nothing.

=cut

sub tag {
    my ($self, %args) = @_;

    return $self;
}

#------------------------------------------------------------------------------

=method add( file => $some_file, source => $other_file )

Adds the specified C<file> (as a L<Path::Class::File>) to this Store.
The path to C<file> is presumed to be somewhere beneath the root
directory of this Store.  If the optional C<source> is given (also as
a L<Path::Class::File>), then that C<source> is first copied to
C<file>.  If C<source> is not specified, then the C<file> must already
exist.  Throws an exception on failure.  Returns a reference to this
Store.

=cut

sub add {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $source = $args{source};

    throw_args "$file does not exist and no source was specified"
        if not -e $file and not defined $source;

    throw_args "$source is not a file"
        if $source and $source->is_dir();

    if ($source) {

        if ( not -e (my $parent = $file->parent()) ) {
          $self->mkpath($parent);
        }

        $self->debug("Copying $source to $file");

        # NOTE: We have to force stringification of the arguments to
        # File::Copy, since older versions don't support Path::Class
        # objects properly.  File::Copy is part of the CORE, and is
        # not dual-lifed, so upgrading it requires a whole new Perl.
        # We're going to be kind and accommodate the old versions.

        File::Copy::copy("$source", "$file")
            or throw_io "Failed to copy $source to $file: $!";
    }

    return $self;
}

#------------------------------------------------------------------------------

=method remove( file => $some_file )

Removes the specified C<file> (as a L<Path::Class::File>) from this
Store.  The path to C<file> is presumed to be somewhere beneath the
root directory of this Store.  Any empty directories above C<file>
will also be removed.  Throws an exception on failure.  Returns a
reference to this Store.

=cut

sub remove {
    my ($self, %args) = @_;

    my $file  = $args{file};

    return $self if not -e $file;

    throw_args "$file is not a file" if -d $file;

    $self->info("Removing file $file");
    $file->remove() or throw_io "Failed to remove $file: $!";

    while (my $dir = $file->parent()) {
        last if $dir->children();
        $self->debug("Removing empty directory $dir");
        $dir->remove();
        $file = $dir;
    }

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

L<Pinto::Store> is the default back-end for a Pinto repository.  It
basically just represents files on disk.  You should look at
L<Pinto::Store::VCS::Svn> or L<Pinto::Store::VCS::Git> for a more
interesting example.

=cut
