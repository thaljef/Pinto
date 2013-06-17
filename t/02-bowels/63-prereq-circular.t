#!perl

use strict;
use warnings;

use Test::More;

use Pinto::PrerequisiteWalker;

use lib 't/lib';
use Pinto::Tester;

#------------------------------------------------------------------------------


my $t = Pinto::Tester->new;

# Foo -> Bar -> Baz -> Foo
$t->populate('AUTHOR/Foo-1 = Foo-1 & Bar~1');
$t->populate('AUTHOR/Bar-1 = Bar-1 & Baz~1');
$t->populate('AUTHOR/Baz-1 = Baz-1 & Foo~1');

#------------------------------------------------------------------------------

{
	my $cb  = sub { 
		my ($prereq) = @_;
		my $dist = $t->pinto->repo->get_distribution(spec => $prereq->as_spec);
		ok defined $dist, "Got distribution for prereq $prereq";
		return $dist;
	};

	my $dist = $t->get_distribution(author => 'AUTHOR', archive => 'Foo-1.tar.gz');
	my $walker = Pinto::PrerequisiteWalker->new(start => $dist, callback => $cb);
	while ($walker->next) {};

	# All we need to do is make sure we get out...
	ok 1, 'Escaped circular dependencies';
}

#------------------------------------------------------------------------------

done_testing;
