#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Tester;

#------------------------------------------------------------------------------
note("This test requires a live internet connection to pull stuff from CPAN");
#------------------------------------------------------------------------------

#
# FCGI and common::sense both generate the .pm files at build time.  So it
# appears that they don't have any packages.  The PackageExctractor class
# has workaround for these
#------------------------------------------------------------------------------

for my $pkg (qw(common::sense FCGI)) {
	my $t = Pinto::Tester->new;
	$t->run_ok(Pull => {targets => $pkg});
	$t->run_ok(List => {});
	$t->stdout_like(qr{$pkg}, "$pkg registered ok");
}

#------------------------------------------------------------------------------

done_testing;

