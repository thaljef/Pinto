#!perl

use strict;
use warnings;

use Test::More (tests => 5);
use Pinto::Schema::Result::Distribution;

#-----------------------------------------------------------------------------

my $attrs = {path => 'F/FO/FOO/Bar-1.2.tar.gz', origin => 'there'};
my $dist = Pinto::Schema::Result::Distribution->new($attrs);

is($dist->origin(), 'there', 'Dist origin');
is($dist->path(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Logical dist path');
is($dist->physical_path(), 'authors/id/F/FO/FOO/Bar-1.2.tar.gz', 'Physical dist path');
is($dist->physical_path('here'), 'here/authors/id/F/FO/FOO/Bar-1.2.tar.gz', 'Physical dist path, with base');

is("$dist", $dist->path(), 'Stringification returns path of dist');

#-----------------------------------------------------------------------------
