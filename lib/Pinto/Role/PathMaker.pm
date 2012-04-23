# ABSTRACT: Something that makes directory paths

package Pinto::Role::PathMaker;

use Moose::Role;

use Path::Class;
use Try::Tiny;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------

=method mkpath( $path )

Creates a directory at the specified path, including any intervening
directories.  Throws an exception on failure.  Returns true if a path
was actually made.  If the path already existed, returns false.

=cut

sub mkpath {
    my ($self, $path) = @_;

    $path = dir($path) if not eval {$path->isa('Path::Class')};

    $self->fatal("$path is not a Path::Class::Dir") if not $path->is_dir;
    $self->fatal("$path is an existing file") if -f $path;

    return 0 if -e $path;

    $self->debug("Making directory $path");

    try   { $path->mkpath }
    catch { $self->fatal("Failed to make directory $path: $_") };

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
