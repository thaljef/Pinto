#!perl

use strict;
use warnings;

use Test::File;
use Test::Warn;
use Test::Exception;
use Test::More (tests => 18);

use File::Temp;
use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto;
use Pinto::Util;
use Pinto::TestConfig;
use Pinto::TestLogger;

#------------------------------------------------------------------------------

my $repos     = dir(File::Temp->newdir());
my $logger    = Pinto::TestLogger->new();
my $config    = Pinto::TestConfig->new(local => $repos);
my $pinto     = Pinto->new(logger => $logger, config => $config);
my $dist_file = file($Bin, qw(data Bar Bar-0.001.tar.gz));

#------------------------------------------------------------------------------
# Creation...
$pinto->create();
repos_file_exists_ok( [qw(modules 02packages.details.txt.gz)] );
repos_file_exists_ok( [qw(modules 02packages.details.local.txt.gz)] );
throws_ok { $pinto->create() } qr/already exists/, 'Cannot create twice';

#------------------------------------------------------------------------------
# Addition...

# Make sure we have clean slate
index_package_not_exists_ok( 'Bar' );
repos_dist_not_exists_ok( 'AUTHOR', $dist_file->basename() );

$pinto->add( dists => $dist_file );
repos_dist_exists_ok( 'AUTHOR', $dist_file->basename() );

index_package_exists_ok('Bar', 'AUTHOR', 'v4.9.1');

throws_ok { $pinto->add(dists => $dist_file) }
   qr/already exists/, 'Cannot add same dist twice';

throws_ok { $pinto->add(dists => $dist_file, author => 'CHAUCEY') }
   qr/owned by AUTHOR/, 'Cannot add package owned by another author';

throws_ok { $pinto->add(dists => 'none_such') }
    qr/does not exist/, 'Cannot add nonexistant dist';

#------------------------------------------------------------------------------
# Removal...

warning_like { $pinto->remove(packages => 'None::Such') }
    qr/is not in the local index/, 'Removing bogus package emits warning';

throws_ok { $pinto->remove(packages => 'Bar', author => 'CHAUCEY') }
    qr/only AUTHOR/, 'Cannot remove package owned by another author';

$pinto->remove( packages => 'Bar' );
repos_dist_not_exists_ok( 'AUTHOR', $dist_file->basename() );
index_package_not_exists_ok( 'Bar' );

# Adding again, with different author...
$pinto->add(dists => $dist_file, author => 'CHAUCEY');
repos_dist_exists_ok( 'CHAUCEY', $dist_file->basename() );

index_package_exists_ok('Bar', 'CHAUCEY', 'v4.9.1');

#------------------------------------------------------------------------------
# TODO: Refactor these into a Test::* class for testing the repos

sub repos_file_exists_ok {
    my ($path, $name) = @_;
    $path = file( $repos, @{$path} );
    return file_exists_ok($path, $name);
}

sub repos_file_not_exists_ok {
    my ($path, $name) = @_;
    $path = file( $repos, @{$path} );
    return file_not_exists_ok($path, $name);
}

sub repos_dist_exists_ok {
    my ($author, $dist_basename, $name) = @_;
    my $author_dir = Pinto::Util::author_dir($repos, qw(authors id), $author);
    my $dist_path = $author_dir->file($dist_basename);
    return file_exists_ok($dist_path, $name);
}

sub repos_dist_not_exists_ok {
    my ($author, $dist_basename, $name) = @_;
    my $author_dir = Pinto::Util::author_dir($repos, qw(authors id), 'AUTHOR');
    my $dist_path = $author_dir->file($dist_basename);
    return file_not_exists_ok($dist_path, $name);
}

sub index_package_exists_ok {
    my ($name, $author, $version) = @_;
    my $pkg = $pinto->idxmgr->master_index->packages->{$name};
    return fail("Package $name is not in the index") if not $pkg;

    my $dist = $pkg->dist();
    is($dist->author(), $author,  'Package has correct author');
    is($pkg->version(), $version, 'Package has correct version');
    return 1;
}


sub index_package_not_exists_ok {
    my ($name) = @_;
    my $pkg = $pinto->idxmgr->master_index->packages->{$name};
    return is(undef, $pkg, "Package $name is still in the index");
}

#------------------------------------------------------------------------------
