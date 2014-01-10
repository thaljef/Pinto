#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Pinto::Tester;
use Pinto::Tester::Util qw(make_dist_archive);

#------------------------------------------------------------------------------

my $source = Pinto::Tester->new;
$source->populate('JOHN/Baz-1.2 = Baz~1.2 & Nuts~2.3');
$source->populate('PAUL/Nuts-2.3 = Nuts~2.3');

#------------------------------------------------------------------------------
# Adding an archive with deep dependencies...

{
    my $archive = make_dist_archive("ME/Foo-Bar-0.01 = Foo~0.01; Bar~0.01 & Baz~1.2");
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( 'Add', { archives => $archive, author => 'ME' } );

    $local->registration_ok('ME/Foo-Bar-0.01/Foo~0.01');
    $local->registration_ok('ME/Foo-Bar-0.01/Bar~0.01');
    $local->registration_ok('JOHN/Baz-1.2/Baz~1.2');
    $local->registration_ok('PAUL/Nuts-2.3/Nuts~2.3');
}

#------------------------------------------------------------------------------
# Adding an archive that has deep unsatisfiable dependencies...

{
    my $archive = make_dist_archive("ME/Foo-Bar-0.01 = Foo~0.01; Bar~0.01 & Baz~2.4");
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_throws_ok( 'Add', { archives => $archive, author => 'ME' }, qr/Cannot find Baz~2.4 anywhere/ );
}

#-----------------------------------------------------------------------------
# Adding an archive that depends on a perl

{
    my $archive = make_dist_archive("ME/Foo-0.01 = Foo~0.01 & perl~5.10.1");
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( 'Add', { archives => $archive, author => 'ME' } );
    $local->registration_ok('ME/Foo-0.01/Foo~0.01');
}

#-----------------------------------------------------------------------------
# Adding an archive that depends on a core module

{
    my $archive = make_dist_archive("ME/Foo-0.01 = Foo~0.01 & Scalar::Util~1.13");
    my $local = Pinto::Tester->new( init_args => { sources => $source->stack_url } );
    $local->run_ok( 'Add', { archives => $archive, author => 'ME' } );
    $local->registration_ok('ME/Foo-0.01/Foo~0.01');
}

#------------------------------------------------------------------------------
{
    my $local = Pinto::Tester->new;

    my $foo2 = make_dist_archive('Foo-2 = Foo~2');
    my $foo1 = make_dist_archive('Foo-1 = Foo~1');

    $local->run_ok( Add => { author => 'ME', archives => $foo2 } );
    $local->run_ok( Add => { author => 'ME', archives => $foo1 } );

    # Notice we added Foo~1 and *then* Foo~1.  So we are downgrading
    $local->stderr_like(qr{Downgrading package ME/Foo-2/Foo~2 to ME/Foo-1/Foo~1});

    # Repository now contains both Foo~1 and Foo~2, but only the
    # older Foo~1 is actually registered on the stack.

    $local->registration_ok('ME/Foo-1.tar.gz/Foo~1');
    $local->registration_not_ok('ME/Foo-2.tar.gz/Foo~2');

    # When we add Bar-1, the stack should still only have Foo~1, even though the
    # newer Foo~2 is available in the repository.  Because Bar only requires Foo~1.

    my $bar1 = make_dist_archive('Bar-1 = Bar~1 & Foo~1');
    $local->run_ok( Add => { author => 'ME', archives => $bar1 } );

    $local->registration_ok('ME/Foo-1.tar.gz/Foo~1');
    $local->registration_ok('ME/Bar-1.tar.gz/Bar~1');

    # Now add Bar-2, which requires newer Foo~2
    my $bar2 = make_dist_archive('Bar-2 = Bar~2 & Foo~2');
    $local->run_ok( Add => { author => 'ME', archives => $bar2 } );

    # The stack should upgrade to Foo~2 to satisfy prereqs
    $local->registration_ok('ME/Foo-2.tar.gz/Foo~2');
    $local->registration_ok('ME/Bar-2.tar.gz/Bar~2');

    $local->registration_not_ok('ME/Foo-1.tar.gz/Foo~1');
    $local->registration_not_ok('ME/Bar-1.tar.gz/Bar~1');
}

#-----------------------------------------------------------------------------

done_testing;
