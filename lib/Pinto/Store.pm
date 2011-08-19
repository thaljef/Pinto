package Pinto::Store;

# ABSTRACT: Storage for a Pinto repository

use Moose;

use Carp;
use File::Copy;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

with qw( Pinto::Role::PathMaker );

#------------------------------------------------------------------------------
# Methods

=method is_initialized()

Returns true if the store appears to be initialized.  In this base
class, it simply means that the working directory exists.  For other
derived classes, this could mean that the working copy is up-to-date.

=cut

sub is_initialized {
    my ($self) = @_;

    return -e $self->config->repos();
}

#------------------------------------------------------------------------------

=method initialize()

This method is called before each batch of Pinto events, and is
responsible for doing any setup work that is required by the Store.
This could include making a directory on the file system, checking out
or updating a working copy, cloning, or pulling commits.  If the
initialization fails, an exception should be thrown.  The default
implementation simply creates a directory.  Returns a reference
to this Store.

=cut

sub initialize {
    my ($self) = @_;

    my $repos = $self->config->repos();
    $self->mkpath($repos);

    return $self;
}

#------------------------------------------------------------------------------

=method finalize(message => 'what happened')

This method is called after each batch of Pinto events and is
responsible for doing any work that is required to commit the Store.
This could include scheduling files for addition/deletion, pushing
commits to a remote repository, and/or making a tag.  If the
finalization fails, an exception should be thrown.  The default
implementation merely logs the message.  Returns a reference
to this Store.

=cut

sub finalize {
    my ($self, %args) = @_;

    my $message = $args{message} || 'Finalizing the store';
    $self->logger->info($message);

    return $self;
}


#------------------------------------------------------------------------------

=method add( file => $some_file, source => $other_file )

Adds the specified C<file> (as a L<Path::Class::File>) to this Store.
The path to C<file> is presumed to be somewhere beneath the root
directory of this Store.  If the optional C<source> is given (also as
a L<Path::Class::File>), then that C<source> is first copied to
C<file>.  If C<source> is not specified, then the C<file> must already
exist.  Croaks on failure.  Returns a reference to this Store.

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

        # NOTE: We have to force stringification of the arguments to
        # File::Copy, since older versions don't support Path::Class
        # objects properly.  File::Copy is part of the CORE, and is
        # not dual-lifed, so upgrading it requires a whole new Perl.
        # We're going to be kind and accommodate the old versions.

        File::Copy::copy("$source", "$file")
            or croak "Failed to copy $source to $file: $!";
    }

    return $self;
}

#------------------------------------------------------------------------------

=method remove( file => $some_file )

Removes the specified C<file> (as a L<Path::Class::File>) from this
Store.  The path to C<file> is presumed to be somewhere beneath the
root directory of this Store.  Any empty directories above C<file>
will also be removed.  Croaks on failure.  Returns a reference to this
Store.

=cut

sub remove {
    my ($self, %args) = @_;

    my $file  = $args{file};

    return $self if not -e $file;

    croak "$file is not a file" if -d $file;

    $self->logger->info("Removing file $file");
    $file->remove() or croak "Failed to remove $file: $!";

    while (my $dir = $file->parent()) {
        last if $dir->children();
        $self->logger->debug("Removing empty directory $dir");
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
