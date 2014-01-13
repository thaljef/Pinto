#!perl

use strict;
use warnings;

use Path::Class;
use FindBin qw($Bin);
use URI::Escape qw(uri_escape);
use File::Temp qw(tempdir);
use IO::Zlib;

use Test::More;

use Pinto::TargetLocator;

#------------------------------------------------------------------------------

my $found;
my $temp_dir  = tempdir(CLEANUP => 1);
my $repos_dir = dir($Bin)->as_foreign('Unix')->stringify() . '/repos';
my @repos_urls = map { URI->new("file://$repos_dir/$_") } qw(a b);
my $class = 'Pinto::TargetLocator';

#------------------------------------------------------------------------------

my $locator = $class->new( repository_urls => \@repos_urls,
                                 cache_dir => $temp_dir );

$found = $locator->locate(target => 'Foo~1.0');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz", 'Located Foo-1.0');

$found = $locator->locate(target => 'Foo~2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz", 'Located Foo-2.0');

for my $url (@repos_urls) {
    my $cache_file = file( $temp_dir, uri_escape($url), '02packages.details.txt.gz' );
    ok( -e $cache_file, "Cache file $cache_file exists" );

    # Erase contents of cache file.  But we still need the standard gzip header
    # or else there will be an exception when we try to open the file later.
    my $fh = IO::Zlib->new($cache_file->stringify, 'wb');
    print $fh '';
    close $fh;
}


$locator = $class->new( repository_urls => \@repos_urls,
                              cache_dir => $temp_dir );

$found = $locator->locate(target => 'Foo~1.0');
is($found, undef, 'Did not find Foo-1.0 in empty cache');

$found = $locator->locate(target => 'Foo~2.0');
is($found, undef, 'Did not find Foo-2.0 in empty cache');

#------------------------------------------------------------------------------

done_testing();


