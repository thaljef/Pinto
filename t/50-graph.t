#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Digest::SHA qw (sha256_hex);

use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $t = Pinto::Tester->new;
my $db = $t->pinto->repo->db;

sub create_kommit { 
  my $attrs = {message => 'fake', username => 'fake'};
  return $db->schema->create_kommit( $attrs )->finalize;
}

#------------------------------------------------------------------------------
{

  # Assume a kommit graph that looks like this:
  #
  #  A-B-E-G
  #    \   /
  #     C-D
  #      \
  #       F

  # Construct the graph in that same time-order:
  my $A = create_kommit;
  my $B = create_kommit;
  $B->add_parent($A);

  my $C = create_kommit;
  $C->add_parent($B);

  my $D = create_kommit;
  $D->add_parent($C);

  my $E = create_kommit;
  $E->add_parent($B);

  my $F = create_kommit;
  $F->add_parent($C);

  my $G = create_kommit;
  $G->add_parent($E);
  $G->add_parent($D);

  # Relations to A
  is_deeply [$A->ancestors], [], 'Ancestors of A';
  is_deeply [$A->descendants], [$B, $C, $D, $E, $F, $G], 'Descendants of A';

  # Relations to B
  is_deeply [$B->ancestors], [$A], 'Ancestors to B';
  is_deeply [$B->descendants], [$C, $D, $E, $F, $G], 'Descendants of B';

  # Relations to C
  is_deeply [$C->ancestors], [$B, $A], 'Ancestors to C';
  is_deeply [$C->descendants], [$D, $F, $G], 'Descendants of C';

  # Relations to D
  is_deeply [$D->ancestors], [$C, $B, $A], 'Ancestors to D';
  is_deeply [$D->descendants], [$G], 'Descendants of D';

  # Relations to E
  is_deeply [$E->ancestors], [$B, $A], 'Ancestors to E';
  is_deeply [$E->descendants], [$G], 'Descendants of E';

  # Relations to F
  is_deeply [$F->ancestors], [$C, $B, $A], 'Ancestors to F';
  is_deeply [$F->descendants], [], 'Descendants of F';

  # Relations to G
  is_deeply [$G->ancestors], [$E, $D, $C, $B, $A], 'Ancestors to G';
  is_deeply [$G->descendants], [], 'Descendants of G';


  # Boolean methods
  ok $A->is_ancestor_to($B), 'A is ancestor to B';
  ok !$B->is_ancestor_to($A), 'B is not ancestor to A';

  ok $B->is_descendant_of($A), 'B is descendant of A';
  ok !$A->is_descendant_of($B), 'A is not descendant of B';

  # parents/children methods
  is_deeply [$A->parents], [], 'A has no parents';
  is_deeply [$B->parents], [$A], 'Parents of B';
  is_deeply [$B->children], [$C, $E], 'Children of B';
  is_deeply [$G->parents], [$D, $E], 'Parents of G';
  is_deeply [$G->children], [], 'G has no children';
}

#------------------------------------------------------------------------------

done_testing;
