#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------
{

  my $t = Pinto::Tester->new;

  # archive_1 contains PkgA~1 and PkgB~1
  my $archive_1 =  make_dist_archive('Dist-1=PkgA~1,PkgB~1,PkgC~1');

  # Put archive_1 on the init stack
  $t->run_ok(Add => {archives => $archive_1, author => 'JOHN', norecurse => 1});

  # Copy the "init" stack to "dev".  Both now have the same PkgA, PkgB and PkgC from archive_1
  $t->run_ok(Copy => {from_stack => 'init', to_stack => 'dev'});

  # TODO: should we allow replacing a pinned dist?
  # $t->run_ok(Pin => {stack => 'dev', targets => ['JOHN/Dist-1.tar.gz']});

  # Create a new "qa" stack
  $t->run_ok(New => {stack => 'qa'});

  # archive_2 contains *different* versions of PkgA and PkgB, but not PkgC
  my $archive_2 =  make_dist_archive('Dist-2=PkgA~2,PkgB~2');

  # Put archive_2 on the qa stack
  $t->run_ok(Add => {archives => $archive_2, author => 'JOHN', stack => 'qa', norecurse => 1});

  # archive_hotfixed has same packages/versions as archive_1, plus additional PkgD~1
  my $archive_hotfixed = make_dist_archive('Dist-Hotfix-1=PkgA~1,PkgB~1,PkgD~1');

  # Now replace archive_1 with archive_hotfixed
  $t->run_ok(Replace => {target => 'JOHN/Dist-1.tar.gz', archive => $archive_hotfixed, author => 'JOHN'});

  # 'init' stack should now have hotfixed versions of PkgA and PkgB, plus PkgD
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgA~1/init');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgB~1/init');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgD~1/init');

  # 'dev' stack should also have the hotfixed versions of PkgA and PkgB, plus PkgD
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgA~1/dev');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgB~1/dev');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgD~1/dev');

  # PkgC should be gone from both stacks because it wasn't in the hotfixed archive
  $t->registration_not_ok('JOHN/Dist-1/PkgC~1/init');
  $t->registration_not_ok('JOHN/Dist-1/PkgC~1/dev');

  # but 'qa' stack should still point to the other versions of PkgA and PkgB
  $t->registration_ok('JOHN/Dist-2/PkgA~2/qa');
  $t->registration_ok('JOHN/Dist-2/PkgB~2/qa');

  # and 'qa' stack should still not have PkgC nor PkgD
  $t->registration_not_ok('JOHN/Dist-1/PkgC~1/qa');
  $t->registration_not_ok('JOHN/Dist-Hotfix-1/PkgD~1/qa');

}
#------------------------------------------------------------------------------

done_testing;
