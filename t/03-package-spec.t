#!perl

use strict;
use warnings;

use Test::More;

use Pinto::PackageSpec;

#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new('Foo-1.2');
  is $spec->name, 'Foo',  'Parsed package name from string';
  is $spec->version, '1.2',  'Parsed package version from string';
  is "$spec", 'Foo-1.2', 'Stringified PackageSpec object';

}
#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new('Foo');
  is $spec->name, 'Foo',  'Parsed package name from string';
  is $spec->version, '0',  'Parsed package version from string without version';
  is "$spec", 'Foo-0', 'Stringified PackageSpec object';

}
#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new(name => 'Foo', version => 1.2);
  is $spec->name, 'Foo',  'Constructor with normal name attribute';
  is $spec->version, '1.2',  'Constructor with normal version version';
  is "$spec", 'Foo-1.2', 'Stringified PackageSpec object';

}
#------------------------------------------------------------------------------

done_testing;
