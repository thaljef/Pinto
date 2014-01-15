#!perl

use strict;
use warnings;

use Path::Class;
use FindBin qw($Bin);

use Test::More (tests => 8);

use Pinto::Locator::Index;

#------------------------------------------------------------------------------

my $repos_dir = dir($Bin)->as_foreign('Unix')->stringify() . '/repos';
my $repos_url = URI->new("file://$repos_dir/a");
my $index     = Pinto::Locator::Index->new( repository_url => $repos_url );

#------------------------------------------------------------------------------

my $pkg = $index->packages->{Foo};

ok($pkg, 'Found package');
is($pkg->{name}, 'Foo', 'Package name');
is($pkg->{version}, '1.0', 'Package version');
is($pkg->{distribution}, 'A/AU/AUTHOR/Foo-1.0.tar.gz', 'Dist path');

#------------------------------------------------------------------------------

my $dist = $index->distributions->{'A/AU/AUTHOR/Foo-1.0.tar.gz'};

ok($dist, 'Found dist');
is($dist->{path}, 'A/AU/AUTHOR/Foo-1.0.tar.gz', 'Dist path');
is($dist->{source}, $repos_url, 'Dist path');
is($dist->{packages}->[0]->{name}, 'Foo', 'Package name');

