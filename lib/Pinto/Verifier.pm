# ABSTRACT: Verifies signatures and checksums for a distribution archive

package Pinto::Verifier;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(debug throw);
use Pinto::Types qw(File Dir Uri);
use MooseX::Types::Moose qw(Bool Str);
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

has strict => (
    is       => 'ro',
    isa      => Bool,
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

has error_message => (
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

=method maybe_verify_embedded()

Unpack the current archive and verify the embedded SIGNATURE file if it exists.

Returns false if embedded signiture exists and does not verify.
Returns true otherwise.

=cut

sub maybe_verify_embedded {
    my ($self) = @_;

    my $cwd_guard = cwd_guard( $self->work_dir );

    if ( -r 'SIGNATURE' ) {
        # trap warnings
        my @warnings = ();

        my $ok = do {
            local $SIG{__WARN__} = sub { push @warnings, @_ };
            local $ENV{GNUPGHOME} = $ENV{PINTO_GNUPGHOME} if $ENV{PINTO_GNUPGHOME};
            Module::Signature::verify() == SIGNATURE_OK;
        };
        $self->_propagate(@warnings) if @warnings;

        return if not $ok;
    }

    return 1;
}

#------------------------------------------------------------------------------

=method verify( $checksums_file )

Verifying the signature for the $checksums_file, then use that file to verify
the current archive.

=cut

sub verify {
    my ( $self, $checksums_file ) = @_;

    if ( !-s $checksums_file ) {
        return;
    }

    if ( _slurp($checksums_file) =~ /BEGIN PGP SIGNATURE/ms ) {

        if ( !$self->verify_attached_signature($checksums_file) ) {
            # XXX We cannot trust the archive, so further processing is
            # neither safe nor valid
            return;

        }
    }
    elsif ($self->strict) {
        throw "Distribution does not have a signed checksums file";
    }

    if ( $self->verify_checksum($checksums_file) ) {
        return 1;
    }
    return;
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
        $self->{error_message} = "Checksums file is broken";
        return;
    }

    if ( my $checksum = $checksums_ref->{$basename}->{sha256} ) {
        if ( $checksum ne Pinto::Util::sha256( $self->local ) ) {
            $self->{error_message} = "Checksum mismatch";
            return;
        }
    }
    else {
        $self->{error_message} = "Checksum not found in checksums file";
        return;
    }

    return 1;
}

#-----------------------------------------------------------------------------

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

    $self->_propagate(@warnings) if @warnings;

    return $ok;
}

#------------------------------------------------------------------------------

sub _propagate {
    my ($self, @warnings) = @_;

    # propagate warnings to chrome
    if (@warnings) {
        warn "WARNINGS for " . $self->local , "\n";

        # warnings are fatal in strict mode
        if ( $self->strict ) {
            throw join '', @warnings;
        }
        else {
            warn '>>> ' . $_ for @warnings;
        }
    }
}

#------------------------------------------------------------------------------

{
    my %cache = ();

    sub _slurp {
        my ($file) = @_;

        return $cache{$file} if exists $cache{$file};

        my $text = file($file)->slurp();
        $text =~ s/\015?\012/\n/g;    # replace CRLF
        $cache{$file} = $text;

        return $text;
    }
}

#-----------------------------------------------------------------------------

1;

__END__
