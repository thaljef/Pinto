package Pinto::Store;

# ABSTRACT: Storage for a Pinto repository

use Moose;

use Try::Tiny;
use File::Copy;
use CPAN::Checksums;

use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Roles

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
should be thrown.  The default implementation does nothing.  Returns a
reference to this Store.

=cut

sub commit {
    my ($self, %args) = @_;

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

sub add_archive {

    my ($self, @args) = @_;

    my $to   = pop @args;
    my $from = shift @args;

    throw_fatal "$to does not exist and no source was specified"
        if not -e $to and not defined $from;

    throw_fatal "$from is not a file"
        if defined $from and not -f $from;

    if ($from) {

        if ( not -e (my $parent = $to->parent()) ) {
          $self->mkpath($parent);
        }

        $self->debug("Copying $from -> $to");

        # NOTE: We have to force stringification of the arguments to
        # File::Copy, since older versions don't support Path::Class
        # objects properly.  File::Copy is part of the CORE, and is
        # not dual-lifed, so upgrading it requires a whole new Perl.
        # We're going to be kind and accommodate the old versions.

        File::Copy::copy("$from", "$to")
            or throw_fatal "Failed to copy $from to $to: $!";
    }

    $self->add_file( file => $to );
    $self->update_checksums( directory => $to->parent() );

    return $self;

}

#------------------------------------------------------------------------------

sub remove_archive {
    my ($self, $archive_path) = @_;

    $self->remove_file( file => $archive_path );

    $self->update_checksums( directory => $archive_path->parent() );

    return $self;
}

#------------------------------------------------------------------------------

sub add_file {
    my ($self, %args) = @_;

    my $file   = $args{file};

    throw_fatal "$file does not exist"
        if not -e $file;

    throw_fatal "$file is not a file"
        if not -f $file;

    return $self;
}

#------------------------------------------------------------------------------

sub remove_file {
    my ($self, %args) = @_;

    my $file = $args{file};

    throw_fatal "$file does not exist"
        if not -e $file;

    throw_fatal "$file is not a file"
        if not -f $file;

    $file->remove()
        or throw_fatal "Failed to remove file $file: $!";

    while (my $dir = $file->parent()) {
        last if $dir->children();
        $self->debug("Removing empty directory $dir");
        $dir->remove() or throw_fatal "Failed to remove directory $dir: $!";
        $file = $dir;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub update_checksums {
    my ($self, %args) = @_;
    my $dir = $args{directory};

    #return 0 if not -e $dir;  # Smells fishy

    my @children = grep { ! Pinto::Util::is_vcs_file($_) } $dir->children();
    return 0 if not @children;

    my $cs_file = $dir->file('CHECKSUMS');

    if ( -e $cs_file && @children == 1 ) {
        $self->remove_file(file => $cs_file);
        return 0;
    }

    $self->debug("Generating $cs_file");

    try   { CPAN::Checksums::updatedir($dir) }
    catch { throw_error("CHECKSUM generation failed for $dir: $_") };

    $self->add_file(file => $cs_file);

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
