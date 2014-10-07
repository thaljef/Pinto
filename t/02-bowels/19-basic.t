#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

use Pinto::Util qw(sha256);

#------------------------------------------------------------------------------

{

    my $t = Pinto::Tester->new;
    my $archive = make_dist_archive('AUTHOR/Dist-1 = PkgA~1 & PkgB~1');
    $t->run_ok( Add => { archives => $archive, author => 'AUTHOR', recurse => 0 } );
    my $dist = $t->get_distribution(author => 'AUTHOR', archive => 'Dist-1.tar.gz');

    is $dist->sha256, sha256($archive), 'SHA digest';
    is $dist->source, 'LOCAL', 'Dist source';
    is $dist->author, 'AUTHOR', 'Dist author';
    is $dist->name, 'Dist', 'Dist name';
    is $dist->vname, 'Dist-1', 'Dist vname';
    is $dist->version, '1', 'Dist version';
    is $dist->is_devel, '', 'Dist maturity';

    my @packages = $dist->packages;
    is scalar @packages, 1, 'Package count';

    my $pkg = $packages[0];
    is $pkg->name, 'PkgA', 'Package name';
    is $pkg->vname, 'PkgA~1', 'Package vname';
    is $pkg->version, '1', 'Package version';
    is $pkg->file, 'lib/PkgA.pm', 'Package file';
    is $pkg->is_simile, 1, 'Package is simile';

    my @prereqs = $dist->prerequisites;
    is scalar @prereqs, 1, 'Prereq count';

    my $prereq = $prereqs[0];
    is $prereq->package_name, 'PkgB', 'Prereq name';
    is $prereq->package_version, '1', 'Prereq version';
}

#-----------------------------------------------------------------------------

done_testing;
