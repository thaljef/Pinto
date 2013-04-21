# ABSTRACT: remove orphaned distribution archives

package App::Pinto::Command::clean;

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT clean

=head1 DESCRIPTION

The database for L<Pinto> is transactional, so failures and aborted
commands do not change the indexes.  However, the filesystem where
distribution archives are physically stored is not transactional and
may become cluttered with archives that are not in the database.

Normally, L<Pinto> tries to clean up those orphaned archives.  But in
some cases it might not.  Running this command will force their
removal.

This command also runs some optimizations on the database.  So if
your repository seems to be running slowly, try running this command
to see if performance improves.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

None.

=cut
