#!perl

use strict;
use warnings;

use Test::More (tests => 19);

use Path::Class;

use Pinto::Tester::Util qw(make_dist make_pkg);

#------------------------------------------------------------------------------

my $dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.001_02.tar.gz');
my $pkg  = make_pkg(name => 'Foo', version => '2.001_02', distribution => $dist);

is($pkg->name(), 'Foo', 'name attribute');
is($pkg->vname(), 'Foo-2.001_02', 'vname attribute');
is($pkg->version(), '2.001_02', 'version attribute');
isa_ok($pkg->version(), 'version', 'version attribute isa version object');
is("$pkg", 'AUTHOR/Foo-2.001_02/Foo-2.001_02', 'default strigification');

#------------------------------------------------------------------------------

$dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.0.tar.gz', source => 'http://remote');
$pkg  = make_pkg(name => 'Foo', distribution => $dist );

is($pkg->vname(), 'Foo-0', 'vname with undef version');

#------------------------------------------------------------------------------

$dist = make_dist(path => 'A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz', source => 'http://remote');
$pkg  = make_pkg(name => 'Foo', distribution => $dist, version => 1.2, is_latest => 1);

my %formats = (
    'n' => 'Foo',
    'N' => 'Foo-1.2',
    'v' => '1.2',
    'x' => '*',
    'm' => 'D',
    'p' => 'A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz',
    's' => 'F',
    'S' => 'http://remote',
    'a' => 'AUTHOR',
    'd' => 'Foo',
    'D' => 'Foo-2.0-TRIAL',
    'w' => '2.0-TRIAL',
    'u' => 'http://remote/authors/id/A/AU/AUTHOR/Foo-2.0-TRIAL.tar.gz',
);

while ( my ($placeholder, $expected) = each %formats ) {
    my $got = $pkg->to_formatted_string("%$placeholder");
    is($got, $expected, "Placeholder: %$placeholder");
}

#------------------------------------------------------------------------------
