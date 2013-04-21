#!perl

use strict;
use warnings;

use Test::More;
use English qw(-no_match_vars);

use Pinto::PackageSpec;

#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new('Foo~1.2');
  is $spec->name, 'Foo',  'Parsed package name from string';
  is $spec->version, '1.2',  'Parsed package version from string';
  is "$spec", 'Foo~1.2', 'Stringified PackageSpec object';

}
#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new('Foo');
  is $spec->name, 'Foo',  'Parsed package name from string';
  is $spec->version, '0',  'Parsed package version from string without version';
  is "$spec", 'Foo~0', 'Stringified PackageSpec object';

}
#------------------------------------------------------------------------------
{

  my $spec = Pinto::PackageSpec->new(name => 'Foo', version => 1.2);
  is $spec->name, 'Foo',  'Constructor with normal name attribute';
  is $spec->version, '1.2',  'Constructor with normal version version';
  is "$spec", 'Foo~1.2', 'Stringified PackageSpec object';

}

#------------------------------------------------------------------------------

{

  # Module::Build first introduced into core in perl 5.9.4
  # Module::Build was first upgraded to 0.038 in perl 5.13.11

  my $spec = Pinto::PackageSpec->new(name => 'Module::Build', version => 0.38);
  is $spec->is_core(in => 'v5.6.1'),  0, "$spec is not in perl 5.6.1";
  is $spec->is_core(in => 'v5.10.1'), 0, "$spec is not in perl 5.10.1";
  is $spec->is_core(in => 'v5.14.2'), 1, "$spec is in perl 5.14.2";

  if ($PERL_VERSION > '5.13.11') {
    is $spec->is_core, 1, "$spec is in *this* perl ($PERL_VERSION)"
  }

}

#------------------------------------------------------------------------------

done_testing;
