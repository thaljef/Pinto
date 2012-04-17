#!perl

use strict;
use warnings;

use Test::More (tests => 25);

use Path::Class;

use Pinto::Tester::Util qw(make_dist_obj);

#-----------------------------------------------------------------------------

my $dist = make_dist_obj(path => 'F/FO/FOO/Bar-1.2.tar.gz');

is($dist->source(), 'LOCAL', 'Source defaults to q{LOCAL}');
is($dist->name(), 'Bar', 'dist name');
is($dist->vname(), 'Bar-1.2', 'dist name');
is($dist->version(), '1.2', 'dist version');
is($dist->is_local(), 1, 'is_local is true when origin eq q{LOCAL}');
is($dist->is_devel(), q{}, 'this is not a devel dist');
is($dist->path(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Logical dist path');
is($dist->archive(), file( qw(authors id F FO FOO Bar-1.2.tar.gz) ), 'Physical archive path');
is($dist->archive('here'), file( qw(here authors id F FO FOO Bar-1.2.tar.gz) ), 'Physical archive path, with base');
is("$dist", 'F/FO/FOO/Bar-1.2.tar.gz', 'Stringifies to path');

#-----------------------------------------------------------------------------

$dist = make_dist_obj(path => 'F/FO/FOO/Bar-4.3_34.tgz', source => 'http://remote');

is($dist->source(), 'http://remote', 'Non-local source');
is($dist->name(), 'Bar', 'dist name');
is($dist->vname(), 'Bar-4.3_34', 'dist vname');
is($dist->version(), '4.3_34', 'dist version');
is($dist->is_local(), q{}, 'is_local is false when dist is remote');
is($dist->is_devel(), 1, 'this is a devel dist');

#------------------------------------------------------------------------------

$dist = make_dist_obj(path => 'A/AU/AUTHOR/Foo-2.0.tar.gz');

my %formats = (
    'm' => 'r',
    'p' => 'A/AU/AUTHOR/Foo-2.0.tar.gz',
    's' => 'l',
    'S' => 'LOCAL',
    'a' => 'AUTHOR',
    'd' => 'Foo',
    'D' => 'Foo-2.0',
    'w' => '2.0',
    'u' => 'UNKNOWN',
);

while ( my ($placeholder, $expected) = each %formats ) {
    my $got = $dist->to_formatted_string("%$placeholder");
    is($got, $expected, "Placeholder: %$placeholder");
}
