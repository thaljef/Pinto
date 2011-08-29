#!perl

use strict;
use warnings;

use Test::More (tests => 17);
use Test::Exception;
use FindBin qw($Bin);
use Path::Class;

use Pinto::Distribution;

#-----------------------------------------------------------------------------

my $dist;

#-----------------------------------------------------------------------------
# Constructing from an index record...

$dist = Pinto::Distribution->new(location => 'F/FO/FOO/Bar-1.2.tar.gz');

is($dist->version(), '1.2', 'Dist version from location');
is($dist->name(), 'Bar', 'Dist name from location');
is($dist->author(), 'FOO', 'Dist author from location');
is($dist->location(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Dist name from location');

is($dist->path(), 'authors/id/F/FO/FOO/Bar-1.2.tar.gz', 'Dist path');
is($dist->path('here'), 'here/authors/id/F/FO/FOO/Bar-1.2.tar.gz', 'Dist path, with base');

is("$dist", $dist->location(), 'Stringification returns location of dist');

#-----------------------------------------------------------------------------
# Constructing from a dist file...

my $dist_file = file( $Bin, qw(data fakes authors id L LO LOCAL FooOnly-0.01.tar.gz) );
$dist = Pinto::Distribution->new_from_file(author => 'AUTHOR', file => $dist_file);

is($dist->version(), '0.01', 'Dist version from file');
is($dist->name(), 'FooOnly', 'Dist name from file');
is($dist->author(), 'AUTHOR', 'Dist author from file');
is($dist->location(), 'A/AU/AUTHOR/FooOnly-0.01.tar.gz', 'Dist name from file');

my @packages = @{ $dist->packages() };
is(scalar @packages, 1, 'Dist had one package');

my $pkg = $packages[0];
is($pkg->name(), 'Foo', 'Extracted package name');
is($pkg->version(), '0.01', 'Extracted package version');

throws_ok { Pinto::Distribution->new_from_file() }
          qr/Must specify a file/, 'No arguments';

throws_ok { Pinto::Distribution->new_from_file(file => 'whatever') }
          qr/Must specify an author/, 'Only file argument';

throws_ok { Pinto::Distribution->new_from_file(file => 'foo.tar.gz', author => 'ME') }
          qr/does not exist/, 'a bogus file';

#-----------------------------------------------------------------------------
