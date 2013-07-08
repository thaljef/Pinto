# ABSTRACT: Static helper functions for testing

package Pinto::Tester::Util;

use strict;
use warnings;

use Readonly;
use Path::Class;
use Apache::Htpasswd;
use File::Temp qw(tempdir);
use Module::Faker::Dist;

use Pinto::Schema;
use Pinto::Util qw(throw);

use base 'Exporter';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly our @EXPORT_OK => qw(
    $MINIMUM_CPANM_VERSION
    make_dist_obj
    make_pkg_obj
    make_dist_struct
    make_dist_archive
    make_htpasswd_file
    parse_pkg_spec
    parse_dist_spec
    parse_reg_spec
    has_cpanm
);

Readonly our %EXPORT_TAGS => ( all => \@EXPORT_OK );

#-------------------------------------------------------------------------------

Readonly our $MINIMUM_CPANM_VERSION => 1.6196;

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

    # AUTHOR / Foo-1.2 .tar.gz = Foo~1.0,Bar~2 & Baz~1.1,Nuts~2.3
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

    my @provides = map { parse_pkg_spec($_) } split /,/, $provides || '';
    my @requires = map { parse_pkg_spec($_) } split /,/, $requires || '';

    return ( $dist, \@provides, \@requires );
}

#------------------------------------------------------------------------------

sub parse_pkg_spec {
    my ($spec) = @_;

    # Looks like: "Foo" or "Foo-1" or "Foo-Bar-2.3.4_1"
    $spec =~ m/^ ( .+? ) (?: [~-] ( [\d\._]+ ) )? $/x
        or throw "Could not parse spec: $spec";

    return { name => $1, version => $2 || 0 };
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

    return $cpanm_ver >= $min_version;
}

#------------------------------------------------------------------------------

1;

__END__
