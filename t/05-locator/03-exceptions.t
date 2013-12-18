#!perl

use strict;
use warnings;

use Test::More (tests => 6);
use Test::Exception;

use Pinto::PackageLocator;

#------------------------------------------------------------------------------

my $class = 'Pinto::PackageLocator';

#------------------------------------------------------------------------------


throws_ok { $class->new()->locate() }
    qr/Must specify spec or distribution/;

throws_ok { $class->new()->locate(spec => 'Foo', distribution => 'Foo.tar.gz') }
    qr/Cannot specify spec and distribution together/;

throws_ok { $class->new()->locate(distribution => 'Foo.tar.gz', latest => 1) }
    qr/Cannot specify latest and distribution together/;

throws_ok { $class->new()->locate(spec => 'Foo~2.3-RC') }
    qr/Invalid version/;

#------------------------------------------------------------------------------
# This next one seems to throw different exceptions, depending on the
# version of perl.  I suspect the exception originates from different
# places, depending on what you have.  So for now, I just test that
# at least some kind of exception is thrown.

my $bogus_urls = [ URI->new('http://__bogus__') ];
dies_ok { $class->new(repository_urls => $bogus_urls)->locate(spec => 'Foo%1.23a') };
