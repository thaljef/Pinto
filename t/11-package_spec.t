#!perl

use strict;
use warnings;

use Test::More (tests => 25);
use Test::Exception;

use Pinto::PackageSpec;

#-------------------------------------------------------------------------------
# Construction with pspec notation...

my $pkg_spec = Pinto::PackageSpec->new('Foo');
is $pkg_spec->name(), 'Foo', 'name from pspec notation: Foo';
is $pkg_spec->version(),  0, 'version from pspec notation: Foo';


$pkg_spec = Pinto::PackageSpec->new('Bar-2.3.4');
is $pkg_spec->name(), 'Bar', 'name from pspec notation: Bar-2.3.4';
is $pkg_spec->version(),  "2.3.4", 'version from pspec notation: Bar-2.3.4';

#-------------------------------------------------------------------------------
# Stringification...

$pkg_spec = Pinto::PackageSpec->new('Foo-1.2');
is "$pkg_spec", 'Foo-1.2', 'Stringification of Foo-1.2';

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
throws_ok { mkspec('Foo', 1) <=> mkspec('Bar', 1) } qr/Cannot compare different packages/,
    'Comparing package specs with different names';

throws_ok { mkspec('Foo', 1) <=> '1.2a' } qr/Invalid version/,
    'Comparing package spec with invalid version string';

throws_ok { mkspec('Foo', 1) <=> {} } qr/Cannot compare HASH with Pinto::PackageSpec/,
    'Comparing incompatible objects';

#-------------------------------------------------------------------------------

sub mkspec {
    my ($n, $v);

    ($n, $v) = @_               if @_ == 2;
    ($n, $v) = ('Test', $_[0])  if @_ == 1;
    ($n, $v) = ('Test', 0)      if not @_;

  return Pinto::PackageSpec->new( name => $n, version => $v);
}

#-------------------------------------------------------------------------------
