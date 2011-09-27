#!perl

use strict;
use warnings;

use Test::More (tests => 13);

use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto::Tester::Util qw(make_dist make_pkg);

#------------------------------------------------------------------------------

my $dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.001_02.tar.gz');
my $pkg  = make_pkg(name => 'Foo', version => '2.001_02', distribution => $dist);

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->vname(), 'Foo-2.001_02', 'vname attribute');
is($pkg->version(), '2.001_02', 'version attribute');
is($pkg->version_numeric(), 2.00102, 'version_numeric attribute');
is($pkg->is_devel(), 1, 'is_devel attribute');
is($pkg->is_local(), 1, 'is_local attribute');
is("$pkg", 'Foo-2.001_02', 'strigifies to vname');

#------------------------------------------------------------------------------

$dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.0.tar.gz', origin => 'http://remote');
$pkg  = make_pkg(name => 'Foo', distribution => $dist );

is($pkg->vname(), 'Foo-undef', 'vname with undef version');
is($pkg->version(), 'undef', 'undef version forced to q{undef}');
is($pkg->version_numeric(), 0, 'undef version numfied to 0');
is($pkg->is_devel(), q{}, 'is_devel is false when version undef');
is($pkg->is_local(), q{}, 'is_local is false when dist is remote');

#------------------------------------------------------------------------------

$dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz');
$pkg  = make_pkg(name => 'Foo', version => '2.0', distribution => $dist);

is($pkg->is_devel(), 1, 'A non-devel package is considered devel when part of a devel dist');
