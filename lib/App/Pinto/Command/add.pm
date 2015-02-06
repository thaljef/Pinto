package App::Pinto::Command::add;

# ABSTRACT: add local archives to the repository

use strict;
use warnings;

#------------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'author=s'                          => 'The ID of the archive author' ],
        [ 'cascade'                           => 'Always pick latest upstream package' ],
        [ 'diff-style=s'                      => 'Set style of diff reports' ],
        [ 'dry-run'                           => 'Do not commit any changes' ],
        [ 'message|m=s'                       => 'Message to describe the change' ],
        [ 'no-fail'                           => 'Do not fail when there is an error' ],
        [ 'no-index|x=s@'                     => 'Do not index matching packages' ],
        [ 'recurse!'                          => 'Recursively pull prereqs (negatable)' ],
        [ 'pin'                               => 'Pin packages to the stack' ],
        [ 'skip-missing-prerequisite|k=s@'    => 'Skip missing prereq (repeatable)' ],
        [ 'skip-all-missing-prerequisites|K'  => 'Skip all missing prereqs' ],
        [ 'stack|s=s'                         => 'Put packages into this stack' ],
        [ 'use-default-message|M'             => 'Use the generated message' ],
        [ 'with-development-prerequisites|wd' => 'Also pull prereqs for development' ],
        [ 'verify-upstream|Z:+'               => 'Verify upstream files before use (repeatable)' ],
    );
}

#------------------------------------------------------------------------------

sub args_attribute { return 'archives' }

#------------------------------------------------------------------------------

sub args_from_stdin { return 1 }

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT add [OPTIONS] ARCHIVE_FILE ...

=head1 DESCRIPTION

This command adds local distribution archives to the repository and
registers their packages on a stack. Then it recursively pulls all the
distributions that are necessary to satisfy their prerequisites.

When locating prerequisite packages, Pinto first looks at the packages
that already exist in the local repository, then Pinto looks at the
packages that are available on the upstream repositories.

=head1 COMMAND ARGUMENTS

Arguments to this command are paths to the distribution archives that
you wish to add.  Each of these files must exist and must be readable.

You can also pipe arguments to this command over STDIN.  In that case,
blank lines and lines that look like comments (i.e. starting with "#"
or ';') will be ignored.

=head1 COMMAND OPTIONS

=over 4

=item --author NAME

Set the identity of the distribution author.  The C<NAME> is automatically
forced to uppercase and must match C</^[A-Z]{2}[-A-Z0-9]*$/> (that means
two ASCII letters followed by zero or more ASCII letters, digits, or
hyphens). Defaults to the C<user> attribute specified in your F<~/.pause>
configuration file if such file exists.  Otherwise, defaults to your
current login username.

=item --cascade

!! THIS OPTION IS EXPERIMENTAL !!

When searching for a prerequisite package, always take the latest
satisfactory version of the package found amongst B<all> the upstream
repositories, rather than just taking the B<first> satisfactory version
that is found.  Remember that Pinto only searches the upstream
repositories when the local repository does not already contain a
satisfactory version of the package.

=item --diff-style=STYLE

Controls the style of the diff reports.  STYLE must be either C<concise> or
C<detailed>.  Concise reports show only one record for each distribution added
or deleted.  Detailed reports show one record for every package added or
deleted.

The default style is C<concise>.  However, the default style can changed by
setting the C<PINTO_DIFF_STYLE> environment variable to your preferred STYLE.
This variable affects the default style for diff reports generated by all
other commands too.

=item --dry-run

Go through all the motions, but do not actually commit any changes to the
repository.  At the conclusion, a diff showing the changes that would have
been made will be displayed.  Use this option to see how upgrades would
potentially impact the stack.

=item --message=TEXT

=item -m TEXT

Use TEXT as the revision history log message.  If you do not use the
C<--message> option or the C<--use-default-message> option, then you will be
prompted to enter the message via your text editor.  Use the C<PINTO_EDITOR>
or C<EDITOR> or C<VISUAL> environment variables to control which editor is
used.  A log message is not required whenever the C<--dry-run> option is set,
or if the action did not yield any changes to the repository.

=item --no-fail

!! THIS OPTION IS EXPERIMENTAL !!

Normally, failure to add an archive (or its prerequisites) causes the
command to immediately abort and rollback the changes to the repository.
But if C<--no-fail> is set, then only the changes caused by the failed
archive (and its prerequisites) will be rolled back and the command
will continue processing the remaining archives.

This option is useful if you want to throw a list of archives into
a repository and see which ones are problematic.  Once you've fixed
the broken ones, you can throw the whole list at the repository
again.

=item --no-index=PACKAGE

=item -x PACKAGE

=item --no-index=/PATTERN

=item -x /PATTERN

!! THIS OPTION IS EXPERIMENTAL !!

Exclude the PACKAGE from the index.  If the argument starts with a slash, then
it is interpreted as a regular expression, and all packages matching the
pattern will be excluded.  Exclusions only apply to the added distributions
(i.e. the arguments to this command) so they do not affect any prerequisited
distributions that may also get pulled.  You can repeat this option to specify
multiple PACKAGES or PATTERNS.

This option is useful when Pinto's indexing is to aggressive and finds
packages that it probably should not.  Remember that Pinto does not promise to
index exactly as PAUSE would.  When using a PATTERN, take care to use a
conservative one so you don't exclude the wrong packages.  Pinto will throw an
exception if you exclude every package in the distribution.

=item --pin

Pins all the packages in the added distributions to the stack, so they
cannot be changed until you unpin them.  The pin does not apply to any
prerequisites that are pulled in for this distribution.  However, you
may pin them separately with the
L<pin|App::Pinto::Command::pin> command, if you so desire.

=item --recurse

=item --no-recurse

Recursively pull any distributions required to satisfy prerequisites
for the targets.  The default value for this option can be configured
in the F<pinto.ini> configuration file for the repository (it is usually
set to 1).  To disable recursion, use C<--no-recurse>.

=item --skip-missing-prerequisite=PACKAGE

=item -k PACKAGE

!! THIS OPTION IS EXPERIMENTAL !!

Skip any prerequisite with name PACKAGE if a satisfactory version cannot be
found.  However, a warning will be given whenever this occurrs.  This option only
has effect when recursively fetching prerequisites for the targets (See also
the C<--recurse> option). This option can be repeated.

=item --skip-all-missing-prerequisites

=item -K

!! THIS OPTION IS EXPERIMENTAL !!

Skips all missing prerequisites if a satisfactory version cannot be found.
However, a warning will be given whenever this occurrs.  This option will
silently override the C<--skip-missing-prerequisite> option and only has
effect when recursively fetching prerequisites for the targets (See also the
C<--recurse> option).

=item --stack=NAME

=item -s NAME

Puts all the packages onto the stack with the given NAME.  Defaults
to the name of whichever stack is currently marked as the default
stack.  Use the L<stacks|App::Pinto::Command::stacks> command
to see the stacks in the repository.

=item --use-default-message

=item -M

Use the default value for the revision history log message.  Pinto
will generate a semi-informative log message just based on the command
and its arguments.  If you set an explicit message with C<--message>,
the C<--use-default-message> option will be silently ignored.

=item --with-development-prerequisites

=item --wd

Also pull development prerequisites so you'll have everything you need
to work on those distributions, in the event that you need to patch them
in the future.  Be aware that most distributions do not actually declare
their development prerequisites.

=item --verify-upstream=[0-5]

=item -Z [0-5]

=item -Z ... -ZZZZZ

!! THIS OPTION IS EXPERIMENTAL !!

Require upstream distribution files to be verified before operating on them.
Repeated use of this argument (up to 5) requires the upstream verification to
be progressively more strict.  You can also set the verification level
explicitly, e.g.,

    --verify-upstream=3

At level 0, no verification is performed. This may be useful if you need to
override the verification level set earlier, say, in a script.

At level 1, we verify the distributions checksum using the upstream CHECKSUMS
file.  This is the default level.

At level 2, we also verify the signature on the upstream CHECKSUMS file if it
has one.  Warnings about unknown or untrusted PGP keys relating to that file
are printed.

At level 3, we also require upstream CHECKSUMS files to be signed.  Warnings
about unknown or untrusted PGP keys relating to that file are now considered
fatal.

At level 4, we also verify the unpacked distribution using the embedded
SIGNATURE file if it exists.  Warnings about unknown or untrusted PGP keys
relating to that file are printed.

At level 5, warnings about unknown or untrusted PGP keys relating to embedded
SIGNATURE files are now considered fatal.

Note that none of these checks are applied to LOCAL distributions, i.e.,
distributions that do not have an upstream CHECKSUMS file.

The impact of this option will largely depend on the your chosen upstream
repositories and state of your current keyring.  Consider using a dedicated
keyring/trustdb via the C<PINTO_GNUPGHOME> environment variable.  See the
documentation for the L<verify|App::Pinto::Command::verify> command for the
rationale and an example.

=back

=cut
