#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw< make_dist_archive >;
use File::Remove qw< remove >;
use Path::Class;

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
my $auth    = 'ME';
my $pkg1    = 'Foo~0.01';
my $pkg2    = 'Bar~0.01';
my $dist    = 'Foo-Bar-0.01';
my $archive = make_dist_archive("$dist=$pkg1,$pkg2");
$t->run_ok( 'Add', { archives => $archive, author => $auth } );

my $default_filename = 'master-' . $t->pinto->repo->get_stack->head->uuid_prefix;

#------------------------------------------------------------------------------

remove(\1, $default_filename); 
$t->run_ok( 'Export', {} );
ok(-e $default_filename, 'default was created');
ok(-e file($default_filename, qw< authors id M ME ME Foo-Bar-0.01.tar.gz >), 'archive is present');
remove(\1, $default_filename); 

remove(\1, 't/prova'); 
$t->run_ok( 'Export', { output => 't/prova' } );
remove(\1, 't/prova'); 

unlink 't/prova.tar.gz';
$t->run_ok( 'Export', { output => 't/prova.tar.gz', output_format => 'tar.gz' } );
$t->run_throws_ok( 'Export', { output => 't/prova.tar.gz', output_format => 'tar.gz' },
qr/output .* is already present/ );
unlink 't/prova.tar.gz';
$t->run_ok( 'Export', { output => 't/prova.tar.gz', output_format => 'tar.gz' } );
unlink 't/prova.tar.gz';

# Create a stack...
my $stack = $t->pinto->repo->create_stack( name => 'test' );
$t->run_ok( 'Add', { archives => $archive, author => $auth, stack => 'test' } );
$default_filename = 'test-' . $t->pinto->repo->get_stack('test')->head->uuid_prefix;
remove(\1, $default_filename); 
$t->run_ok( 'Export', { stack => 'test' } );
ok(-e $default_filename, 'default was created for specific stack');
ok(-e file($default_filename, qw< authors id M ME ME Foo-Bar-0.01.tar.gz >), 'archive is present');
remove(\1, $default_filename); 


#------------------------------------------------------------------------------

done_testing;

