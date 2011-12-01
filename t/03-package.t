#!perl

use strict;
use warnings;

use Test::More (tests => 9);

use Path::Class;

use Pinto::Tester::Util qw(make_dist make_pkg);

#------------------------------------------------------------------------------

my $dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.001_02.tar.gz');
my $pkg  = make_pkg(name => 'Foo', version => '2.001_02', distribution => $dist);

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->vname(), 'Foo-2.001_02', 'vname attribute');
is($pkg->version(), '2.001_02', 'version attribute');
is($pkg->version_numeric(), 2.00102, 'version_numeric attribute');
is("$pkg", 'Foo-2.001_02/Foo-2.001_02', 'strigifies to dist/pkg vnames');

#------------------------------------------------------------------------------

$dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.0.tar.gz', source => 'http://remote');
$pkg  = make_pkg(name => 'Foo', distribution => $dist );

is($pkg->vname(), 'Foo-undef', 'vname with undef version');
is($pkg->version(), 'undef', 'undef version forced to q{undef}');
is($pkg->version_numeric(), 0, 'undef version numfied to 0');

#------------------------------------------------------------------------------
