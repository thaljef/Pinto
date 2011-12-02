#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;
use FindBin qw($Bin);

use Pinto::Tester;

#------------------------------------------------------------------------------

my $fakes     = dir( $Bin, qw(data fakepan repos a) );
my $auth_dir  = $fakes->subdir( qw(authors id L LO LOCAL) );

my $dist    = 'FooOnly-0.01.tar.gz';
my $pkg     = 'Foo-0.01';
my $archive = $auth_dir->file($dist);

# A couple local authors...
my $auth1 = 'AUTHOR1';
my $auth2 = 'AUTHOR2';

#------------------------------------------------------------------------------
# Setup...

my $t = Pinto::Tester->new();
my $pinto = $t->pinto();

#------------------------------------------------------------------------------
# Adding a local dist...

$pinto->new_batch();
$pinto->add_action( 'Add', archive => $archive, author => $auth1 );
$t->result_ok( $pinto->run_actions() );


$t->package_loaded_ok( "$auth1/$dist/$pkg", 1 );
$t->path_exists_ok( [qw( authors id A AU AUTHOR1 CHECKSUMS)] );

#-----------------------------------------------------------------------------
# Addition exceptions...

$t->reset_buffer();
$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $auth1);
$t->result_not_ok( $pinto->run_actions() );
$t->log_like( qr/$dist already exists/,
              'Cannot add same dist twice' );

$t->reset_buffer();
$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $auth2);
$t->result_not_ok( $pinto->run_actions() );
$t->log_like( qr/Only author $auth1 can update package Foo/,
              'Cannot add package owned by another author');

$t->reset_buffer();
$pinto->new_batch();
$pinto->add_action('Add', archive => 'none_such', author => $auth1);
$t->result_not_ok( $pinto->run_actions() );
$t->log_like( qr/none_such does not exist/,
          'Cannot add nonexistant archive' );

#-----------------------------------------------------------------------------
# Adding devel release to non-devel repository

$dist = 'Fee-0.02_1.tar.gz';
$pkg  = 'Fee-0.02_1';
$archive = $auth_dir->file($dist);

$t->reset_buffer();
$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $auth1);
$t->result_ok( $pinto->run_actions() );

$t->package_loaded_ok( "$auth1/$dist/$pkg", 0 );
$t->log_like( qr/Developer distribution .* will not be indexed/,
              'Got warning about devel dist' );

#-----------------------------------------------------------------------------
# Adding devel release to a devel repository

$t = Pinto::Tester->new( creator_args => {devel => 1} );
$pinto = $t->pinto();

$pinto->new_batch();
$pinto->add_action('Add', archive => $archive, author => $auth1);
$t->result_ok( $pinto->run_actions() );

$t->package_loaded_ok( "$auth1/$dist/$pkg", 1 );
$t->log_unlike( qr/Developer distribution .* will not be indexed/,
                'Did not get warning about devel dist');


done_testing();
