# ABSTRACT: Static helper functions for testing

package Pinto::Tester::Util;

use strict;
use warnings;

use Readonly;
use Path::Class;
use Apache::Htpasswd;
use File::Temp qw(tempdir);
use Module::Faker::Dist;

use CPAN::Checksums;
use Module::Signature;
use Pinto::ArchiveUnpacker;
use Cwd::Guard qw(cwd_guard);

use Pinto::Schema;
use Pinto::Util qw(throw);

use base 'Exporter';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(
    make_dist_obj
    make_pkg_obj
    make_dist_struct
    make_dist_archive
    make_htpasswd_file
    parse_pkg_spec
    parse_dist_spec
    parse_reg_spec
    has_cpanm
    corrupt_distribution
    corrupt_checksums
    sign_checksums
    sign_dist_archive
);

Readonly our %EXPORT_TAGS => ( all => \@EXPORT_OK );

#-------------------------------------------------------------------------------

sub make_pkg_obj {
    my %attrs = @_;
    return Pinto::Schema->resultset('Package')->new_result( \%attrs );
}

#------------------------------------------------------------------------------

sub make_dist_obj {
    my %attrs = @_;
    return Pinto::Schema->resultset('Distribution')->new_result( \%attrs );
}

#------------------------------------------------------------------------------

sub make_dist_archive {
    my ($spec_or_struct) = @_;

    my $struct =
        ref $spec_or_struct eq 'HASH'
        ? $spec_or_struct
        : make_dist_struct($spec_or_struct);

    my $temp_dir     = tempdir( CLEANUP => 1 );
    my $fake_dist    = Module::Faker::Dist->new($struct);
    my $fake_archive = $fake_dist->make_archive( { dir => $temp_dir } );

    return file($fake_archive);
}

#------------------------------------------------------------------------------

sub make_dist_struct {
    my ($spec) = @_;

    my ( $dist, $provides, $requires ) = parse_dist_spec($spec);

    for my $provision ( @{$provides} ) {
        my $version = $provision->{version};
        my $name    = $provision->{name};
        my $file    = "lib/$name.pm";
        $dist->{provides}->{$name} = { file => $file, version => $version };
    }

    for my $requirement ( @{$requires} ) {
        my $version = $requirement->{version};
        my $name    = $requirement->{name};
        $dist->{requires}->{$name} = $version;
    }

    return $dist;
}

#------------------------------------------------------------------------------

sub parse_dist_spec {
    my ($spec) = @_;

    # AUTHOR / Foo-1.2 .tar.gz = Foo~1.0;Bar~2 & Baz~1.1;Nuts~2.3
    # -------- ------- -------   ------------- ------------------
    #    |        |       |           |               |
    #  auth     dist     ext       provides       requires
    #
    # author:    optional, defaults to 'LOCAL'
    # extension: optional, discarded
    # requires:  optional
    # All whitespace is ignored

    $spec =~ s{\s+}{}g;    # Remove any whitespace
    $spec =~ m{ ^ (?: ([^/]+) /)? (.+?) (?: .tar.gz)? = ([^&]+) (?: & (.+) )? $ }mx
        or throw "Could not parse distribution spec: $spec";

    my ( $author, $dist, $provides, $requires ) = ( $1, $2, $3, $4 );

    $dist = parse_pkg_spec($dist);
    $dist->{cpan_author} = $author || 'LOCAL';

    my @provides = map { parse_pkg_spec($_) } split /;/, $provides || '';
    my @requires = map { parse_pkg_spec($_) } split /;/, $requires || '';

    return ( $dist, \@provides, \@requires );
}

#------------------------------------------------------------------------------

sub parse_pkg_spec {
    my ($spec) = @_;

    # Looks like: "Foo" or "Foo-1" or "Foo-Bar-2.3.4_1"
    $spec =~ m/^ ( .+? ) (?: [~-] ( [\d\._]+ ) )? $/x
        or throw "Could not parse spec: $spec";

    # In older perls, capture vers are read-only
    my ($name, $version) = ($1, $2);

    # Permit '@' as alternative to '==''
    $version =~ s/^ @ / == /x if $version;

    return { name => $name, version => $version || 0 };
}

#------------------------------------------------------------------------------

sub parse_reg_spec {
    my ($spec) = @_;

    # Remove all whitespace from spec
    $spec =~ s{\s+}{}g;

    # Spec looks like "AUTHOR/Foo-Bar-1.2/Foo::Bar-1.2/stack/+"
    my ( $author, $dist_archive, $pkg, $stack_name, $is_pinned ) = split m{/}x, $spec;

    # Spec must at least have these
    throw "Could not parse pkg spec: $spec"
        if not( $author and $dist_archive and $pkg );

    # Append the usual suffix to the archive
    $dist_archive .= '.tar.gz' unless $dist_archive =~ m{\.tar\.gz$}x;

    # Normalize the is_pinned flag
    $is_pinned = ( $is_pinned eq '*' ? 1 : 0 ) if defined $is_pinned;

    # Parse package name/version
    my ( $pkg_name, $pkg_version ) = split m{~}x, $pkg;

    # Set defaults
    $stack_name  ||= 'master';
    $pkg_version ||= 0;

    return ( $author, $dist_archive, $pkg_name, $pkg_version, $stack_name, $is_pinned );
}

#------------------------------------------------------------------------------

sub make_htpasswd_file {
    my ( $username, $password, $file ) = @_;

    $file ||= file( tempdir( CLEANUP => 1 ), 'htpasswd' );
    $file->touch;    # Apache::Htpasswd requires the file to exist

    Apache::Htpasswd->new($file)->htpasswd( $username, $password );

    return $file;
}

#------------------------------------------------------------------------------

sub has_cpanm {
    my $min_version = shift || 0;

    require File::Which;

    my $cpanm_exe = File::Which::which('cpanm') or return 0;

    my ($cpanm_ver) = qx{$cpanm_exe --version} =~ m{version ([\d._]+)};

    throw "Failed to determine the version of $cpanm_exe" if $? >> 8;

    return $cpanm_ver >= $min_version;
}

#------------------------------------------------------------------------------

sub corrupt_distribution {
    my ($repo, $author, $archive) = @_;

    # Append junk to the end of the archive, so that it can still be unpacked,
    # but the checksums will be invalid.

    my $dist = $repo->get_distribution(author => $author, archive => $archive);
    my $fh = $dist->native_path->opena() or die $!;
    print $fh 'GaRbAgE'; undef  $fh;

    return;
}

#------------------------------------------------------------------------------

sub corrupt_checksums {
    my ($repo, $author, $archive) = @_;

    # Append junk to the end of the corresponding CHECKSUMS, so that it is
    # still valid, but signature tests will fail

    my $dist = $repo->get_distribution(author => $author, archive => $archive);
    my $checksums = file($dist->native_path->parent, 'CHECKSUMS');
    my $fh = $dist->native_path->opena() or die $!;
    print $fh '# GaRbAgE'; undef  $fh;

    return;
}

#------------------------------------------------------------------------------

sub sign_checksums {
    my ($repo, $author, $archive, $trusted) = @_;

    my $dist = $repo->get_distribution(author => $author, archive => $archive);

    my $dir = $dist->native_path->parent;

    # these are the keys used by our testing keyring
    my $key = $trusted ? 'C5713B29' : '90D594AF';

    local $CPAN::Checksums::SIGNING_KEY     = $key;
    local $CPAN::Checksums::SIGNING_PROGRAM = "gpg --clearsign --default-key ";
    CPAN::Checksums::updatedir($dir);

    return;
}

#------------------------------------------------------------------------------

sub sign_dist_archive {
    my ($archive, $trusted) = @_;

    # these are the keys used by our testing keyring
    # TODO have to figure out how to pass this to Module::Signature.
    my $key = $trusted ? 'C5713B29' : '90D594AF';

    # unpack into a temporary directory

    my $unpacker = Pinto::ArchiveUnpacker->new(archive => $archive);
    my $dir = $unpacker->unpack();
    {
        my $cwd_guard = cwd_guard($dir) or die "failed chdir to $dir: $Cwd::Guard::Error";
        Module::Signature::sign(overwrite => 1);
    }

    # TODO there has got to be a more portable way to do this
    if ($archive =~ /\.zip$/) {
        system('zip', '-r', $archive, $dir) == 0
            or die "Failed to create new zip archive: $!";
    }
    else {
        system('tar', 'zcf', $archive, $dir) == 0
            or die "Failed to create new tar archive: $!";
    }

    return;
}

#------------------------------------------------------------------------------

1;

__END__
