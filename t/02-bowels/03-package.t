#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;

use lib 'tlib';
use Pinto::Tester::Util qw(make_dist_obj make_pkg_obj);

#------------------------------------------------------------------------------

my $dist = make_dist_obj(author => 'AUTHOR', archive => 'Foo-2.001_02.tar.gz');
my $pkg  = make_pkg_obj(name => 'Foo', version => '2.001_02', distribution => $dist);

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->vname(), 'Foo~2.001_02', 'vname attribute');
is($pkg->version(), '2.001_02', 'version attribute');
isa_ok($pkg->version(), 'version', 'version attribute isa version object');
is("$pkg", 'AUTHOR/Foo-2.001_02/Foo~2.001_02', 'default strigification');

#------------------------------------------------------------------------------

$dist = make_dist_obj(author => 'AUTHOR', archive => 'Foo-2.0.tar.gz', source => 'http://remote');
$pkg  = make_pkg_obj(name => 'Foo', distribution => $dist );

is($pkg->vname(), 'Foo~0', 'vname with undef version');

#------------------------------------------------------------------------------

$dist = make_dist_obj(author => 'AUTHOR', archive => 'Foo-2.0-TRIAL.tar.gz', source => 'http://remote');
$pkg  = make_pkg_obj(name => 'Foo', distribution => $dist, version => 1.2);

my %formats = (
    'p' => 'Foo',
    'P' => 'Foo~1.2',
    'v' => '1.2',
    'm' => 'd',
    'h' => 'A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz',
    's' => 'f',
    'S' => 'http://remote',
    'a' => 'AUTHOR',
    'd' => 'Foo',
    'D' => 'Foo-2.0-TRIAL',
    'V' => '2.0-TRIAL',
    'u' => 'http://remote/authors/id/A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz',
);

while ( my ($placeholder, $expected) = each %formats ) {
    my $got = $pkg->to_string("%$placeholder");
    is($got, $expected, "Placeholder: %$placeholder");
}

#------------------------------------------------------------------------------

done_testing();

