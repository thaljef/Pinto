
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
  my $archive_1 =  make_dist_archive('Dist-1=PkgA~1,PkgB~1');

  # Put archive_1 on the init stack
  $t->run_ok(Add => {archives => $archive_1, author => 'JOHN', norecurse => 1});

  # Copy the "init" stack to "dev".  Both now have the same PkgA and PkgB from archive_1
  $t->run_ok(Copy => {from_stack => 'init', to_stack => 'dev'});

  # TODO: replacing a pinned dist is not yet supported!
  # $t->run_ok(Pin => {stack => 'init', targets => ['JOHN/Dist-1.tar.gz']});

  # Create a new "qa" stack
  $t->run_ok(New => {stack => 'qa'});

  # archive_2 contains *different* versions of PkgA and PkgB
  my $archive_2 =  make_dist_archive('Dist-2=PkgA~2,PkgB~2');

  # Put archive_2 on the qa stack
  $t->run_ok(Add => {archives => $archive_2, author => 'JOHN', stack => 'qa', norecurse => 1});

  # archive_hotfixed has same version numbers as archive_1, but different file name
  my $archive_hotfixed = make_dist_archive('Dist-Hotfix-1=PkgA~1,PkgB~1');

  # Now replace archive_1 with archive_hotfixed
  $t->run_ok(Replace => {target => 'JOHN/Dist-1.tar.gz', archive => $archive_hotfixed, author => 'JOHN'});

  # 'init' stack should now have hotfixed versions of PkgA and PkgB
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgA~1/init');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgB~1/init');

  # 'dev' stack should also have the hotfixed versions of PkgA and PkgB
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgA~1/dev');
  $t->registration_ok('JOHN/Dist-Hotfix-1/PkgB~1/dev');

  # but 'qa' stack should still point to the other versions
  $t->registration_ok('JOHN/Dist-2/PkgA~2/qa');
  $t->registration_ok('JOHN/Dist-2/PkgB~2/qa');

}
#------------------------------------------------------------------------------

done_testing;
