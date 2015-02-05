# ABSTRACT: Verifies signatures and checksums for a distribution archive

package Pinto::Verifier;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(debug throw);
use Pinto::Types qw(File Dir Uri);
use MooseX::Types::Moose qw(Bool Str Int);
use Pinto::ArchiveUnpacker;

use Cwd::Guard qw(cwd_guard);
use Module::Signature qw(SIGNATURE_OK);
use Path::Class qw(file);
use Safe;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( Pinto::Role::UserAgent );

has local => (
    is       => 'ro',
    isa      => File,
    coerce   => 1,
    required => 1,
);

has upstream => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has level => (
    is       => 'ro',
    isa      => Int,
    default  => 0,
);

has upstream_checksums => (
    is       => 'ro',
    isa      => File,
    builder  => '_build_upstream_checksums',
    init_arg => undef,
    coerce   => 1,
    lazy     => 1,
);

has local_checksums => (
    is       => 'ro',
    isa      => File,
    builder  => '_build_local_checksums',
    init_arg => undef,
    coerce   => 1,
    lazy     => 1,
);

has unpacker => (
    is       => 'ro',
    isa      => 'Pinto::ArchiveUnpacker',
    default  => sub { Pinto::ArchiveUnpacker->new( archive => $_[0]->local ) },
    init_arg => undef,
    lazy     => 1,
);

has work_dir => (
    is       => 'ro',
    isa      => Dir,
    default  => sub { $_[0]->unpacker->unpack },
    init_arg => undef,
    lazy     => 1,
);

has failure => (
    is       => 'rw',
    isa      => Str,
    default  => '',
    init_arg => undef,
);

#-----------------------------------------------------------------------------

sub _build_local_checksums {
    my ($self) = @_;
    my $source = $self->local;
    $source =~ s{/[^/]*$}{/CHECKSUMS};
    return $source;
};

#-----------------------------------------------------------------------------

sub _build_upstream_checksums {
    my ($self) = @_;
    my $source =  $self->upstream;
    $source =~ s{/[^/]*$}{/CHECKSUMS};
    return $self->mirror_temporary($source);
}

#-----------------------------------------------------------------------------

=method verify_upstream()

Verify the current archive using the upstream CHECKSUMS file.

=cut

sub verify_upstream {
    my ($self) = @_;
    debug "Verifying upstream distribution archive";
    return $self->verify( $self->upstream_checksums );
}

#------------------------------------------------------------------------------

=method verify_local()

Verify the current archive using the local CHECKSUMS file.

=cut

sub verify_local {
    my ($self) = @_;
    debug "Verifying local distribution archive";
    return $self->verify( $self->local_checksums );
}

#------------------------------------------------------------------------------

=method verify( $checksums_file )

Verifying the current archive using the given $checksums_file.  The strictness
of the verification process depends on the current verification level.

At level 0, no verification is performed.

At level 1, we verify the distributions checksum using the given CHECKSUMS file

At level 2, we also verify the signature on the given CHECKSUMS file, if it has
one.  Warnings about unknown or untrusted PGP keys relating to that file are
printed.

At level 3, we require the CHECKSUMS file to be signed.  Warnings about
unknown or untrusted PGP keys relating to that file are now considered fatal.

At level 4, we also verify the unpacked distribution using the embedded
SIGNATURE file, if it exists.  Warnings about unknown or untrusted PGP keys
relating to that file are printed.

At level 5, warnings about unknown or untrusted PGP keys relating to embedded
SIGNATURE files are now considered fatal.

=cut

sub verify {
    my ( $self, $checksums_file ) = @_;

    return 1 if $self->level == 0;

    if ( ! -e $checksums_file ) {
        $self->failure("Distribution does not have a checksums_file");
        return;
    }

    if ($self->level >= 2) {
        if ( _slurp($checksums_file) =~ /BEGIN PGP SIGNATURE/ms ) {

            if ( ! $self->verify_attached_signature($checksums_file) ) {
                return;
            }
        }
        elsif ($self->level >= 3 ) {
            $self->failure("Distribution does not have a signed checksums file");
            return;
        }
    }

    if ( ! $self->verify_checksum($checksums_file) ) {
        return;
    }

    if ($self->level >= 4) {
        if (! $self->verify_embedded_signature()) {
            return;
        }
    }

    return 1;
}

#------------------------------------------------------------------------------

=method verify_attached_signature($file)

Verify the attached PGP signature in $file.

=cut

sub verify_attached_signature {
    my ( $self, $file ) = @_;

    # trap warnings
    my @warnings = ();

    my $ok = do {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        local $ENV{GNUPGHOME} = $ENV{PINTO_GNUPGHOME} if $ENV{PINTO_GNUPGHOME};
        Module::Signature::_verify($file) == SIGNATURE_OK;
    };

    if (@warnings) {

        # propagate warnings
        warn "CHECKSUM SIGNATURE WARNINGS for " . $self->local , "\n";
        warn '>>> ' . $_ for @warnings;

        if ($self->level >= 3 ) {
            $self->failure("Checksum signature test emits warnings");
            return;
        }
    }

    if (!$ok) {
        $self->failure("Attached signature does not verify");
        return;
    }

    return 1;
}

#-----------------------------------------------------------------------------

=method verify_checksum( $checksums_file )

Verify the checksum for the current archive using the corresponding sha256
value from the $checksums_file.

=cut

sub verify_checksum {
    my ( $self, $checksums_file ) = @_;

    my $basename = $self->local->basename;

    my $text          = _slurp($checksums_file);
    my $checksums_ref = Safe->new->reval($text);

    if ( !ref $checksums_ref or ref $checksums_ref ne 'HASH' ) {
        $self->{failure} = "Checksums file is broken";
        return;
    }

    if ( my $checksum = $checksums_ref->{$basename}->{sha256} ) {
        if ( $checksum ne Pinto::Util::sha256( $self->local ) ) {
            $self->{failure} = "Checksum mismatch";
            return;
        }
    }
    else {
        $self->{failure} = "Checksum not found in checksums file";
        return;
    }

    return 1;
}

#-----------------------------------------------------------------------------


=method verify_embedded_signature()

Unpack the current archive and verify the embedded SIGNATURE file if it exists.

Returns false if embedded signature exists and does not verify.
Returns true otherwise.

=cut

sub verify_embedded_signature {
    my ($self) = @_;

    my $dir = $self->work_dir;
    my $cwd_guard = cwd_guard($dir) or die "Failed chdir to $dir: $Cwd::Guard::Error";

    if ( -r 'SIGNATURE' ) {

        # trap warnings
        my @warnings = ();

        my $ok = do {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            local $ENV{GNUPGHOME} = $ENV{PINTO_GNUPGHOME} if $ENV{PINTO_GNUPGHOME};
            Module::Signature::verify() == SIGNATURE_OK;
        };

        if (@warnings) {

            # propagate warnings
            warn "EMBEDDED SIGNATURE WARNINGS for " . $self->local , "\n";
            warn '>>> ' . $_ for @warnings;

            if ($self->level >= 5 ) {
                $self->failure("Embedded signature warnings");
                return;
            }
        }

        return if not $ok;
    }

    return 1;
}

#------------------------------------------------------------------------------

{
    my %cache = ();

    sub _slurp {
        my ($filename) = @_;

        return $cache{$filename} if exists $cache{$filename};

        my $file = file($filename);

        # CHECKSUMS files should be much less than a few MB
        $file->stat->size < 100_000_000
                or throw "$filename too big to slurp";

        my $text = $file->slurp()
            or throw "could not slurp $filename";

        $text =~ s/\015?\012/\n/g;    # replace CRLF

        $cache{$filename} = $text;

        return $text;
    }
}

#-----------------------------------------------------------------------------

1;

__END__
