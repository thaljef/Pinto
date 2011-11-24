#!perl

use strict;
use warnings;

use Test::More (tests => 19);
use Test::Exception;

use Pinto::PackageSpec;

#-------------------------------------------------------------------------------

# Basic...
is mkspec()    <=> mkspec(),     0, '<=> equal numbers';
is mkspec(1.0) <=> mkspec(2.0), -1, '<=> ineqal numbers';
is mkspec(1.0) <= mkspec(2.0),   1, 'less-than-or-equal ineqal numbers';
is mkspec(1.0) >= mkspec(2.0),  '', 'greater-than-or-equal inequal numbers';
is mkspec(1.0) == mkspec(2.0),  '', '== inequal numbers';

is mkspec('1.0.1') <=> mkspec('2.0.1'), -1, '<=> strings';
is mkspec('1.0.1') <= mkspec('2.0.1'),   1, 'less-than-or-equal strings';
is mkspec('1.0.1') >= mkspec('2.0.1'),  '', 'greater-than-or-equal strings';
is mkspec('1.0.1') == mkspec('2.0.1'),  '', 'inequal strings';

# Conversion...
is mkspec('1.0.1') <=> '2.0.1', -1, '<=> strings';
is mkspec('1.0.1') <=  '2.0.1',   1, 'less-than-or-equal strings';
is mkspec('1.0.1') >=  '2.0.1',  '', 'greater-than-or-equal strings';
is mkspec('1.0.1') ==  '2.0.1',  '', 'equal strings';

# Conversion, reversed...
is '1.0.1' <=> mkspec('2.0.1'), -1, '<=> strings';
is '1.0.1' <= mkspec('2.0.1'),   1, 'less-than-or-equal strings';
is '1.0.1' >= mkspec('2.0.1'),  '', 'greater-than-or-equal strings';
is '1.0.1' == mkspec('2.0.1'),  '', 'equal strings';

# Invalid...
throws_ok { mkspec('Foo', 1) <=> mkspec('Bar', 1) } qr/Cannot compare/,
    'Comparing package specs with different names';

throws_ok { mkspec('Foo', 1) <=> '1.2a' } qr/Invalid version/,
    'Comparing package spec with invalid version string';

#-------------------------------------------------------------------------------

sub mkspec {
    my ($n, $v);

    ($n, $v) = @_               if @_ == 2;
    ($n, $v) = ('Test', $_[0])  if @_ == 1;
    ($n, $v) = ('Test', 0)      if not @_;

  return Pinto::PackageSpec->new( name => $n, version => $v);
}

#-------------------------------------------------------------------------------
