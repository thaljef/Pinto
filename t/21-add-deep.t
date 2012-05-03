#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2=Baz-1.2~Nuts-2.3');
$source->populate('PAUL/Nuts-2.3=Nuts-2.3');

#------------------------------------------------------------------------------

{
  my $archive = make_dist_archive("ME/Foo-Bar-0.01=Foo-0.01,Bar-0.01~Baz-1.2");
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  $local->run_ok('Add', {archives => $archive, author => 'ME'});

  $local->registration_ok('ME/Foo-Bar-0.01/Foo-0.01');
  $local->registration_ok('ME/Foo-Bar-0.01/Bar-0.01');
  $local->registration_ok('JOHN/Baz-1.2/Baz-1.2');
  $local->registration_ok('PAUL/Nuts-2.3/Nuts-2.3');
}

#------------------------------------------------------------------------------

{
  my $archive = make_dist_archive("ME/Foo-Bar-0.01=Foo-0.01,Bar-0.01~Baz-2.4");
  my $local = Pinto::Tester->new(init_args => {sources => $source->root_url});
  $local->run_throws_ok( 'Add', {archives => $archive, author => 'ME'},
                          qr/Cannot find prerequisite Baz-2.4/);
}

#-----------------------------------------------------------------------------

done_testing;
