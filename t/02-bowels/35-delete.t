#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;

#------------------------------------------------------------------------------

my $dist_auth = 'AUTHOR';
my $dist_name = 'Dist-1.0.tar.gz';
my $dist_path = "$dist_auth/$dist_name";
my @auth_dir  = qw(authors id A AU AUTHOR);
my @pkgs      = qw(PkgA~1 PkgB~1);

my @files_to_check = (
    [ @auth_dir, $dist_name ],
    [ @auth_dir, 'CHECKSUMS' ],
    [ qw(stacks master), @auth_dir, $dist_name ],
    [ qw(stacks master), @auth_dir, 'CHECKSUMS' ],
);

#------------------------------------------------------------------------------

# Add a dist...
$t->populate( "$dist_auth/$dist_name=" . join ';', @pkgs );
$t->registration_ok("$dist_auth/$dist_name/$_/master/-") for @pkgs;

# Now pin it...
$t->run_ok( Pin => { targets => 'PkgA' } );
$t->registration_ok("AUTHOR/Dist-1.0/$_/master/*") for @pkgs;

# Make extra sure it is really there
$t->path_exists_ok($_) for @files_to_check;

# Get the dist so we can look it up later
my $repo = $t->pinto->repo;
my $dist = $repo->get_distribution( author => $dist_auth, archive => $dist_name );
ok defined $dist, "Got distribution $dist_name back from DB";

#-----------------------------------------------------------------------------

# Now try to delete
$t->run_throws_ok( Delete => { targets => $dist_path }, qr/cannot be deleted/ );

# Delete with force
$t->run_ok( Delete => { targets => $dist_path, force => 1 } );

# Now make sure it is gone
my $dist_id = $dist->id;
my $schema  = $repo->db->schema;

is $schema->search_distribution( { id => $dist_id } )->count, 0, 'Records are gone from distribution table';

is $schema->search_package( { distribution => $dist_id } )->count, 0, 'Records are gone from package table';

is $schema->search_registration( { distribution => $dist_id } )->count, 0, 'Records are gone from registration table';

# Make extra sure it is really gone
$t->path_not_exists_ok($_) for @files_to_check;

#------------------------------------------------------------------------------

done_testing;

