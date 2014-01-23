# ABSTRACT: permanently remove an archive

package App::Pinto::Command::delete;

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub command_names { return qw(delete remove del rm) }

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return ( [ 'force' => 'Delete even if packages are pinned' ], );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'targets'; }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1; }

#------------------------------------------------------------------------------
1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT delete [OPTIONS] TARGET ...

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

B<IMPORTANT:>  This command is dangerous.  If you just want to remove
packages or distributions from a stack, then you should probably be looking 
at the L<unregister|App::Pinto::Command::unregister> command instead.

This command permanently removes an archive from the repository, thereby 
unregistering it from all stacks and wiping it from all history (as if 
it had never been put in the repository).  Beware that once an archive 
is deleted it cannot be recovered.  There will be no record that the
archive was ever added or deleted, and this change cannot be undone.

To merely remove packages from a stack (while preserving the archive),
use the L<unregister|App::Pinto::Command::unregister> command.

=head1 COMMAND ARGUMENTS

Arguments are the targets that you want to delete.  Targets are
specified as C<AUTHOR/FILENAME>.  For example:

  SHAKESPEARE/King-Lear-1.2.tar.gz

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --force

Deletes the archive even if its packages are pinned to a stack.  Take
care when deleting pinned packages, as it usually means that
particular package is important to someone.

=back

=cut
