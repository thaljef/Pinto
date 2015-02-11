#!/usr/bin/env perl

# Maintenance script to help keep the documentation for the evolving
# --verify-upstream option up to date and consistent across all commands that
# use it.

use strict;
use warnings;

use Path::Class qw(file);

my $data = do { local $/ = undef; <DATA> };

my @puller_commands = qw( add install pull update );

for my $command (@puller_commands) {
    my $filename = sprintf('lib/App/Pinto/Command/%s.pm', $command);
    my $file = file($filename);
    my $content = $file->slurp;

    # Replace the --verify-upstream POD with our DATA section
    $content =~ s{
        ^=item\ --verify-upstream .*? $ # start of the verify option
        \s+ ^=item .+? $                # skip 1st alternative
        \s+ ^=item .+? $                # skip 2nd alternative
        .+?                             # everything in the middle
        (?=^=)                          # the start of the next pod section
    }{$data}xms;

    $file->spew($content);
};

__DATA__
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
override a verification level set that has been set earlier on the command
line.

At level 1, we verify the distributions checksum using the upstream CHECKSUMS
file. This gives you some assurance that the distribution archive has not be
corrupted during transfer.  This is a good level to use if your upstream
source is on a different system and you trust the network between your system
and upstream.

At level 2, we also verify the signature on the upstream CHECKSUMS file if it
has one.  Warnings about unknown or untrusted PGP keys relating to that file
are printed.  This is a good level to use if you do not necessarily trust the
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
relating to that file are printed.  This is a good level to use if you want to
be alerted about distributions that have been signed by authors you have yet
to verify.

At level 5, warnings about unknown or untrusted PGP keys relating to embedded
SIGNATURE files are now considered fatal.  This is the level to use if you
actively verify all authors who sign their distributions.

Note that none of these checks are applied to LOCAL distributions, i.e.,
distributions that do not have an upstream CHECKSUMS file.

The impact of this option will largely depend on the your chosen upstream
repositories and state of your current keyring.  Consider maintaining
a dedicated keyring/trustdb via the C<PINTO_GNUPGHOME> environment variable.
See the documentation for the L<verify|App::Pinto::Command::verify> command
for the rationale and an example.

