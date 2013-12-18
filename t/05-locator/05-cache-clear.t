
use strict;
use warnings;

use Path::Class;
use FindBin qw($Bin);
use File::Temp qw(tempdir);

use Test::More;

use Pinto::PackageLocator;

#------------------------------------------------------------------------------

my $found;
my $temp_dir  = tempdir(CLEANUP => 1);
my $repos_dir = dir($Bin)->as_foreign('Unix')->stringify() . '/repos';
my @repos_urls = map { URI->new("file://$repos_dir/$_") } qw(a b);

#------------------------------------------------------------------------------

my $locator = Pinto::PackageLocator->new( repository_urls => \@repos_urls,
                                           cache_dir => $temp_dir );

$found = $locator->locate(spec => 'Foo~1.0');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz", 'Located Foo-1.0');

$found = $locator->locate(spec => 'Foo~2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz", 'Located Foo-2.0');

my @index_files = map { $_->index_file } $locator->indexes();
ok(-e $_, 'Index file exists') for @index_files;

$locator->clear_cache();
ok(! -e $_, 'Index file removed by clear_cache()') for @index_files;

$found = $locator->locate(spec => 'Foo~1.0');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz", 'Located Foo-1.0 again');

$found = $locator->locate(spec => 'Foo~2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz", 'Located Foo-2.0 again');
ok(-e $_, 'Index file restored after calling locate()') for @index_files;

#-------------------------------------------------------------------------------

done_testing();
