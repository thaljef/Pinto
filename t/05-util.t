#!perl

use strict;
use warnings;

use Test::More (tests => 2);

use Pinto::Util;
use Path::Class;

#-------------------------------------------------------------------------------

my $author = 'joseph';
my $expect = dir('J/JO/JOSEPH');

is(Pinto::Util::author_dir($author), $expect, 'Author dir path for joseph');

#-------------------------------------------------------------------------------

$author = 'JO';
$expect = dir('J/JO/JO');

is(Pinto::Util::author_dir($author), $expect, 'Author dir path for JO');

#-------------------------------------------------------------------------------
