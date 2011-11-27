package Pinto::Role::PathMaker;

# ABSTRACT: Something that makes directory paths

use Moose::Role;

use Path::Class;
use English qw(-no_match_vars);

use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Roles

with qw(Pinto::Interface::Loggable);

#------------------------------------------------------------------------------

=method mkpath( $path )

Creates a directory at the specified path, including any intervening
directories.  Throws an exception on failure.  Returns true if a path
was actually made.  If the path already existed, returns false.

=cut

sub mkpath {
    my ($self, $path) = @_;

    $path = dir($path) if not eval {$path->isa('Path::Class')};

    throw_fatal "$path is not a Path::Class::Dir" if not $path->is_dir();
    throw_fatal "$path is an existing file" if -f $path;

    return 0 if -e $path;

    $self->debug("Making directory $path");

    eval { $path->mkpath(); 1}
        or throw_fatal "Failed to make directory $path: $EVAL_ERROR";

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__
