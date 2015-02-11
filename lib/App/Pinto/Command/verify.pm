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
        [ 'all|a'               => 'Verify everything in the repository' ],
          [ 'authors|A=s'       => 'Limit to matching author identities' ],
          [ 'distributions|D=s' => 'Limit to matching distribution names' ],
          [ 'packages|P=s'      => 'Limit to matching package names' ],
          [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
          [ 'stack|s=s'         => 'Limit to contents of this stack' ],
          [ 'level|Z:+'         => 'Require files to be verified more strictly (repeatable)' ],
          [ 'local'             => 'Use only use local CHECKSUMS for verification' ],
          [ 'nice=s'            => 'Limit the rate of upstream connections' ],
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

The extent of the checks can be controlled via the C<--level> option.  By
default, only the existence of distribution archives is checked.  More advance
checks may require a suitable PGP setup.

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

=item  --level=[0-5]

=item -Z [0,5]

=item -Z ... -ZZZZZ

Require distribution files to be verified more strictly.  Repeated use of this
argument (up to 5) requires the verification to be progressively more strict.
You can also set the verification level explicitly, e.g.,

    --level=3

At level 0, no special verification is performed: we only check for file
existence.  This is the default level of verification.

At level 1, we verify the distributions checksum using the upstream CHECKSUMS
file. This gives you some assurance that the distribution archives have not be
corrupted during transfer.  This is a good level to use if your upstream
source is on a different system and you trust the network between your system
and upstream.

At level 2, we also verify the signature on the upstream CHECKSUMS file if it
has one.  Warnings about unknown or untrusted PGP keys relating to that file
are printed. This is a good level to use if you do not necessarily trust the
network between your system and upstream (because they do not use HTTPS).  At
this level we silently ignore warnings about the PAUSE Batch Signing Key
(450F89EC) being unknown or untrusted, since this key is to sign the CHECKSUMS
files for all CPAN distributions.

At level 3, we also require upstream CHECKSUMS files to be signed.  Warnings
about unknown or untrusted PGP keys relating to that file are now considered
fatal. This is a good level to use if you only use upstream sources that sign
there distributions and you actively manage the keys that you trust.  At this
level we do not ignore warnings about the PAUSE Batch Signing Key.

At level 4, we also verify the unpacked distribution using the embedded
SIGNATURE file if it exists.  Warnings about unknown or untrusted PGP keys
relating to that file are printed. Warnings about unknown or untrusted PGP
keys relating to that file are printed. This is a good level to use if you
want to be alerted about distributions that have been signed by authors you
have yet to verify.

At level 5, warnings about unknown or untrusted PGP keys relating to embedded
SIGNATURE files are now considered fatal. This is the level to use if you
actively verify all authors who sign their distributions.

Note that none of these checks are applied to LOCAL distributions, i.e.,
distributions that do not have an upstream CHECKSUMS file.

The impact of this option will largely depend on the your chosen upstream
repositories and state of your current keyring.  Consider using a dedicated
keyring/trustdb via the C<PINTO_GNUPGHOME> environment variable as described
below.

=item --local

Modify the verification steps to use use local CHECKSUMS files instead of
upstream.  This only has an effect of the verification level is greater than
0.  This option can be used, say, to verify your local checksums and
signatures before publishing a repository.

=item --nice

Change the rate at which we connect to upstream repositories.  In order to not
overly stress upstream, we wait for short time between each CHECKSUMS
file download.  This option allows you to set this delay in milliseconds.
The default is 500 milliseconds. A setting of 0 disables the delay.

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
