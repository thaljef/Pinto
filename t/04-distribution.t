#!perl

use strict;
use warnings;

use Test::More (tests => 11);
use Test::Exception;

use Pinto::Distribution;

#-----------------------------------------------------------------------------

my $dist;

#-----------------------------------------------------------------------------

$dist = Pinto::Distribution->new(location => 'F/FO/FOO/Bar-1.2.tar.gz');

is($dist->version(), '1.2', 'Dist version from location');
is($dist->name(), 'Bar', 'Dist name from location');
is($dist->author(), 'FOO', 'Dist author from location');
is($dist->location(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Dist name from location');

#-----------------------------------------------------------------------------

$dist = Pinto::Distribution->new(author => 'FOO', file => 'Bar-1.2.tar.gz');

is($dist->version(), '1.2', 'Dist version from file');
is($dist->name(), 'Bar', 'Dist name from file');
is($dist->author(), 'FOO', 'Dist author from file');
is($dist->location(), 'F/FO/FOO/Bar-1.2.tar.gz', 'Dist name from file');

#-----------------------------------------------------------------------------

throws_ok { Pinto::Distribution->new() }
          qr/Must specify either/, 'No arguments';

throws_ok { Pinto::Distribution->new(file => 'whatever') }
          qr/Must specify either/, 'Only file argument';

throws_ok { Pinto::Distribution->new(location => 'whatever', file => 'foo.tar.gz') }
          qr/Cannot specify location with file/, 'location and file argument';

#-----------------------------------------------------------------------------