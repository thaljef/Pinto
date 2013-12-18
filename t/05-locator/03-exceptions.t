#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::TargetLocator;

#------------------------------------------------------------------------------

my $class = 'Pinto::TargetLocator';

#------------------------------------------------------------------------------

throws_ok { $class->new()->locate() }
    qr/Invalid arguments/;

throws_ok { $class->new()->locate(spec => 'Foo~2.3-RC') }
    qr/Invalid prerequisite spec/;

#------------------------------------------------------------------------------
# This next one seems to throw different exceptions, depending on the
# version of perl.  I suspect the exception originates from different
# places, depending on what you have.  So for now, I just test that
# at least some kind of exception is thrown.

my $bogus_urls = [ URI->new('http://__bogus__') ];
dies_ok { $class->new(repository_urls => $bogus_urls)->locate(spec => 'Foo%1.23a') };

#------------------------------------------------------------------------------

done_testing;