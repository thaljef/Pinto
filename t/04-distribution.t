#!perl

use strict;
use warnings;

use Test::More (tests => 18);

use Path::Class;

use Pinto::Schema;

#-----------------------------------------------------------------------------

my $dist = make_dist(path => 'F/FO/FOO/Bar-1.2.tar.gz');

is($dist->origin(), 'LOCAL', 'Origin defaults to q{LOCAL}');
is($dist->name(), 'Bar', 'dist name');
is($dist->vname(), 'Bar-1.2', 'dist name');
is($dist->version(), '1.2', 'dist version');
is($dist->version_numeric(), '1.2', 'dist version_numeric');
is($dist->is_local(), 1, 'is_local is true when origin eq q{LOCAL}');
is($dist->is_devel(), q{}, 'this is not a devel dist');
is($dist->path(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Logical dist path');
is($dist->physical_path(), file( qw(authors id F FO FOO Bar-1.2.tar.gz) ), 'Physical dist path');
is($dist->physical_path('here'), 'here/authors/id/F/FO/FOO/Bar-1.2.tar.gz', 'Physical dist path, with base');
is("$dist", 'F/FO/FOO/Bar-1.2.tar.gz', 'Stringifies to path');

#-----------------------------------------------------------------------------

$dist = make_dist(path => 'F/FO/FOO/Bar-4.3_34.tgz', origin => 'http://remote');

is($dist->origin(), 'http://remote', 'Non-local origin');
is($dist->name(), 'Bar', 'dist name');
is($dist->vname(), 'Bar-4.3_34', 'dist vname');
is($dist->version(), '4.3_34', 'dist version');
is($dist->version_numeric(), 4.334, 'dist version_numeric');
is($dist->is_local(), q{}, 'is_local is true when origin eq q{LOCAL}');
is($dist->is_devel(), 1, 'this is a devel dist');

#-----------------------------------------------------------------------------

sub make_dist {
    my %attrs = @_;
    return Pinto::Schema->resultset('Distribution')->new_result( \%attrs );
}
