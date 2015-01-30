package App::Pinto::Command::verify;

# ABSTRACT: report archives that are missing

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'all|a'             => 'Verify everything in the repository'],
        [ 'authors|A=s'       => 'Limit to matching author identities' ],
        [ 'distributions|D=s' => 'Limit to matching distribution names' ],
        [ 'packages|P=s'      => 'Limit to matching package names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'stack|s=s'         => 'Limit to contents of this stack' ],
        [ 'strict'            => 'Make verification more paranoid' ],
        [ 'files-only'        => 'Skip crytographic checks' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Multiple arguments are not allowed')
        if @{$args} > 1;

    $opts->{stack} = $args->[0]
        if $args->[0];

    $self->usage_error('Cannot specify a stack when using --all')
        if $opts->{stack} && $opts->{all};

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT verify [STACK] [OPTIONS]

=head1 DESCRIPTION

This command reports issues with distributions in the repository.

Distributions that are defined in the repository database, but the archives
are not actually present are problematic.  This could occur when L<Pinto>
aborts unexpectedly due to an exception or you terminate a command
prematurely.

Distributions with invalid checksums or checksums file signatures (checking
both local and upstream), or with invalid embedded signatures are problematic.
This may occur if the distributions have been corrupted on disk or in
transport, or sourced from a corrupted upstream repository.

At the moment, it isn't clear how to fix these situations.  In a future
release you might be able to replace the archive for the distribution.  But
for now, this command simply lets you know if something has gone wrong in your
repository.

For a large repository, it can take a long time to verify everything. So
consider using the C<--authors>, C<--packages>, C<--distributions>, or
C<--stack> options to narrow the scope.  By default only distributions in the
default stack are checked.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the stack as
an argument. So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT verify --stack dev
  pinto --root REPOSITORY_ROOT verify dev

A stack specified as an argument in this fashion will override any stack
specified with the C<--stack> option.  If a stack is not specified by neither
argument nor option, then it defaults to the stack that is currently marked as
the default stack.

=head1 COMMAND OPTIONS

=over 4

=item --all

=item -a

Verify every package in every distribution that exists in the entire repository,
including distributions that are not currently registered on any stack.  When
the C<--all> option is used, then the stack argument and C<--stack> option are
not allowed.

=item --authors=PATTERN

=item -A PATTERN

Limit the verification operation to records where the distribution's author
identity matches C<PATTERN>.  The C<PATTERN> will be interpreted as
a case-insensitive regular expression.  Take care to use quotes if your
C<PATTERN> contains any special shell metacharacters.

=item --distributions=PATTERN

=item -D PATTERN

Limit the verification operation to records where the distribution archive name
matches C<PATTERN>.  The C<PATTERN> will be interpreted as a case-sensitive
regular expression.  Take care to use quotes if your C<PATTERN> contains any
special shell metacharacters.

=item --packages=PATTERN

=item -P PATTERN

Limit the verification operation to distributions containing package name matching
C<PATTERN>.  The C<PATTERN> will be interpreted as a case-sensitive regular
expression.  Take care to use quotes if your C<PATTERN> contains any special
shell metacharacters.

=item --stack=NAME

=item -s NAME

Apply the verification operation to the contents of the stack with the given NAME.
Defaults to the name of whichever stack is currently marked as the default
stack.  Use the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.  This option cannot be used with the C<--all>
option.

=item --pinned

When limiting to a particular stack, further limit the verification operation
to packages that are pinned.

=item --strict

Modifies the verification process to make all warnings fatal B<and> insisting
that all upstream checksums files are signed.  Only distributions with trusted
checksums file signatures and embeded signatures will verify in this case.

=item --files-only

Skip crytographic checks (checksums and signatures) and just check for
distribution file existence. Use tthis option to revert to the behaviour
before these checks were introduced.

=back

=head1 USING A DEDICATED GNUPG KEYRING/TRUSTDB

Verification may generate a lot of messages like the following:

    WARNING: This key is not certified with a trusted signature!
    Primary key fingerprint: XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX

To get rid of the message you have to add the key to your default keyring
(after independent verification) and give it 'Ultimate Trust'.  This is not
ideal given the amount of effort required to verify a key to the point where
you are willing to assign such a high level of trust.

An alternative is to maintain and use an dedicated keyring solely for Pinto
verification. Adding the PAUSE Batch Signing Key (450F89EC) and giving it
'Ultimate Trust' is probably fine after verifying this key from a couple of
sources.  Verifying AUTHOR keys via email may be good enough for the purposes
of a Pinto verification.

If you are using GnuPG, you can use the environment variable PINTO_GNUPGHOME to
instruct pinto to use an alternate keyring/trustdb, e.g,

    # Set up an alternate location for your keyring and trustdb
    mkdir ~/myrepo/gnupg
    chmod 700 ~/myrepo/gnupg
    cp ~/.gnupg/gpg.conf ~/myrepo/gnupg/

    # Download and import the PAUSE Batch Signing Key
    gpg --homedir=~/myrepo/gnupg --recv-keys 450F89EC

    # Edit the PAUSE key to give it ultimate trust
    gpg --homedir=~/myrepo/gnupg -edit 450F89EC

    # Set pinto to use the new keyring and trustdb
    PINTO_GNUPGHOME=~/myrepo/gnupg; export PINTO_GNUPGHOME
    pinto pull Module::Signature
    ...

=back

=cut
