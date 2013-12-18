#!perl

use strict;
use warnings;

use FindBin qw($Bin);
use Path::Class;
use Test::More (tests => 10);

use Pinto::TargetLocator;

#------------------------------------------------------------------------------

my $found;
my $repos_dir = dir($Bin)->as_foreign('Unix')->stringify() . '/repos';
my @repos_urls = map { URI->new("file://$repos_dir/$_") } qw(a b);

my $locator = Pinto::TargetLocator->new( repository_urls => \@repos_urls );

#------------------------------------------------------------------------------
# Locate first...


$found = $locator->locate(spec => 'Foo');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz",
   'Locate by package spec');

$found = $locator->locate(spec => 'Bar');
is($found, undef, 'Locate non-existant package spec');

$found = $locator->locate(spec => 'AUTHOR/Foo-1.0.tar.gz');
is($found, "file://$repos_dir/a/authors/id/A/AU/AUTHOR/Foo-1.0.tar.gz",
    'Locate by dist path');

$found = $locator->locate(spec => 'AUTHOR/Bar-1.0.tar.gz');
is($found, undef, 'Locate non-existant dist path');

$found = $locator->locate(spec => 'Foo~2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
    'Locate by package name and decimal version');

$found = $locator->locate(spec => 'Foo~v1.2.0');
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
    'Locate by package name and vstring');

$found = $locator->locate(spec => 'Foo@3.0');
is($found, undef, 'Locate non-existant version');

#------------------------------------------------------------------------------
# Locate latest...

$found = $locator->locate(spec => 'Foo', latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name');

$found = $locator->locate(spec => 'Foo~1.0', latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name and decimal version');

$found = $locator->locate(spec => 'Foo>=v1.0.5', latest => 1);
is($found, "file://$repos_dir/b/authors/id/A/AU/AUTHOR/Foo-2.0.tar.gz",
   'Locate latest by package name and vstring');





