#!perl

use strict;
use warnings;

use Test::More (tests => 43);

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data ineligible fakes) );
my $source    = URI->new("file://$fakes");
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );
my $dist_name = 'FooOnly-0.01.tar.gz';
my $archive   = $auth_dir->file($dist_name);

# A local author...
my $LOCAL1 = 'LOCAL1';

# This is a bit confusing.  CPAN::Faker creates all the packages under
# the author 'LOCAL'.  But we are treating the fake CPAN as a
# foreign source.  So the author seems "foreign" to Pinto, but is
# "local" to the fake CPAN.  Just pretend you didn't see this next line.
my $FOREIGN = 'LOCAL';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new(creator_args => {source => $source});
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Updating from a foreign repository...

$pinto->new_batch();
$pinto->add_action('Update');
$t->result_ok( $pinto->run_actions() );

print $t->bufferstr();
