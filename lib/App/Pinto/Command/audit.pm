package App::Pinto::Command::audit;

# ABSTRACT: audit the distibutions in a stack

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( audit ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ( $self, $app ) = @_;

    return (
        [ 'all|a'             => 'Audit everything in the repository' ],
        [ 'authors|A=s'       => 'Limit to matching author identities' ],
        [ 'distributions|D=s' => 'Limit to matching distribution names' ],
        [ 'packages|P=s'      => 'Limit to matching package names' ],
        [ 'pinned!'           => 'Limit to pinned packages (negatable)' ],
        [ 'stack|s=s'         => 'Audit contents of this stack' ],
        [ 'strict'            => 'Make verification warnings fatal'],

        # operation
    );
} ## end sub opt_spec

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

  pinto --root=REPOSITORY_ROOT audit [OPTIONS]

=head1 DESCRIPTION

!! THIS COMMAND IS EXPERIMENTAL !!

This command audits the packages that are currently registered on a particular
stack, or all the packages in the entire repository.  In the future we hope to
offer a number of audit operations, but for now simply verifying the
signatures of the checksums from both local and upstream distributions.

For a large repository, it can take a long time to audit everything. So
consider using the C<--packages> or C<--distributions> options to narrow the
scope.

=head1 COMMAND ARGUMENTS

As an alternative to the C<--stack> option, you can also specify the stack as
an argument. So the following examples are equivalent:

  pinto --root REPOSITORY_ROOT audit --stack dev
  pinto --root REPOSITORY_ROOT audit dev

A stack specified as an argument in this fashion will override any stack
specified with the C<--stack> option.  If a stack is not specified by neither
argument nor option, then it defaults to the stack that is currently marked as
the default stack.

=head1 COMMAND OPTIONS

=over 4

=item --all

=item -a

Apply the audit operation to every package in every distribution that exists
in the entire repository, including distributions that are not currently
registered on any stack.  When the C<--all> option is used, then the stack
argument and C<--stack> option are not allowed.

=item --authors=PATTERN

=item -A PATTERN

Limit the audit operation to records where the distribution's author identity
matches C<PATTERN>.  The C<PATTERN> will be interpreted as a case-insensitive
regular expression.  Take care to use quotes if your C<PATTERN> contains any
special shell metacharacters.

=item --distributions=PATTERN

=item -D PATTERN

Limit the audit operation to records where the distribution archive name
matches C<PATTERN>.  The C<PATTERN> will be interpreted as a case-sensitive
regular expression.  Take care to use quotes if your C<PATTERN> contains any
special shell metacharacters.

=item --packages=PATTERN

=item -P PATTERN

Limit the audit operation to distributions containing package name matching
C<PATTERN>.  The C<PATTERN> will be interpreted as a case-sensitive regular
expression.  Take care to use quotes if your C<PATTERN> contains any special
shell metacharacters.

=item --pinned

Limit the audit operation to packages that are pinned.  This option has no
effect when using the C<--all> option.


=item --stack=NAME

=item -s NAME

Apply the audit operation to the contents of the stack with the given NAME.
Defaults to the name of whichever stack is currently marked as the default
stack.  Use the L<stacks|App::Pinto::Command::stacks> command to see the
stacks in the repository.  This option cannot be used with the C<--all>
option.

=item --strict

Modifies the verification process to make all warnings fatal and insisting
that all upstream checksums files are signed.  Only distributions with trusted
checksums file signatures and embeded signatures will verify in this case.

=back

=head1 Using a dedicated GnuPG keyring/trustdb

Currently auditing will generate a lot of messages like the following:

    WARNING: This key is not certified with a trusted signature!
    Primary key fingerprint: XXXX XXXX XXXX XXXX XXXX  XXXX XXXX XXXX XXXX XXXX

To get rid of the message you have to add the key to your default keyring
(after independently verification) and give it 'Ultimate Trust'.  This is not
ideal given the amount of effort required to verify a key to the point where
you are willing to assign such a high level of trust.

An alternative is to maintain and use an dedicated keyring solely for Pinto
audits. Adding the PAUSE Batch Signing Key (450F89EC) and giving it 'Ultimate
Trust' is probably fine after verifying this key from a couple of sources.
Verifying AUTHOR keys via email is probabaly good enough for the purposes of
an audit.

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

=head1 TODO

=over

=item Save audit results to the DB for later querying

An audit run can take a long time.  It might be usefull to be able to query
a previous audit and extract specific pieces of infomation.  E.g., listing the
distributions that failed", listing the distributions with embedded SIGNATURE
files, regenerating the summary from the last audit.

=item More audit operations

Data from CPANTS could be used to highlight distributions that may deserve
a closer inspection.

=back

=cut
