#!perl

use strict;
use warnings;

use Test::More (tests => 3);
use Test::Exception;

use Pinto::Package;


#------------------------------------------------------------------------------

my $pkg = Pinto::Package->new( name    => 'Foo',
                               file    => 'Foo-1.2.tar.gz',
                               version => '2.4',
                               author  => 'CHAUCER' );

is($pkg->file(), 'C/CH/CHAUCER/Foo-1.2.tar.gz', 'With explicit author');

#------------------------------------------------------------------------------

$pkg = Pinto::Package->new( name    => 'Foo',
                            file    => 'C/CH/CHAUCER/Foo-1.2.tar.gz',
                            version => '2.4' );

is($pkg->file(), 'C/CH/CHAUCER/Foo-1.2.tar.gz', 'Author implied by file name');

#------------------------------------------------------------------------------

my %args = ( name    => 'Foo',
             file    => 'Foo-1.2.tar.gz',
             version => '2.4' );

dies_ok { Pinto::Package->new(%args) } 'Unable to compute author from path';

#------------------------------------------------------------------------------
