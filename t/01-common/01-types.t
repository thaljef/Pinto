#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Path::Class;
use FindBin qw($Bin);
use lib dir( $Bin, 'lib' )->stringify();

use TestClass;

#-----------------------------------------------------------------------------

my $t = TestClass->new();

$t->file('foo/bar/baz');
is( ref $t->file(), 'Path::Class::File', 'Coerced file from string' );

$t->dir('foo/bar/baz');
is( ref $t->dir(), 'Path::Class::Dir', 'Coerced dir from string' );

$t->uri('http://nuts');
is( ref $t->uri(), 'URI::http', 'Coerced URI from string' );

$t->author('foobar');
is( $t->author, 'FOOBAR', 'Author coerced to uppercase' );
lives_ok { $t->author('FOO-123') } q{Author name can contain trailing numbers};
throws_ok { $t->author('FOO_BAR') } qr/must match/, 'Author must be alphanumeric';
throws_ok { $t->author('F') } qr/must match/,       'Author must be at least 2 chars';
throws_ok { $t->author('F6') } qr/must match/,      'First 2 chars of author must be letters';
throws_ok { $t->author(undef) } qr/must match/,     'Author must not be undef';
throws_ok { $t->author('') } qr/must match/,        'Author must have length';

lives_ok { $t->stack('MyStack') } q{MyStack is a valid stack name};
lives_ok { $t->stack('My_Stack-1.2') } q{My_Stack-1.2 is a valid stack name};
throws_ok { $t->stack('foo bar!') } qr/alphanumeric/, 'StackName must be alphanumeric';
throws_ok { $t->stack(undef) } qr/alphanumeric/,      'StackName not be undef';
throws_ok { $t->stack('') } qr/alphanumeric/,         'StackName must have length';

# XXX: Do we still need StackAll?
lives_ok { $t->stack_all('%') } q{StackAll as "%"};
dies_ok { $t->stack_all('') } 'Invalid StackAll';
dies_ok { $t->stack_all(undef) } 'Invalid StackAll';
dies_ok { $t->stack_all('X') } 'Invalid StackAll';

lives_ok { $t->stack_default(undef) } q{StackDefault as undef};
dies_ok { $t->stack_default('') } 'Invalid StackDefault';
dies_ok { $t->stack_default('X') } 'Invalid StackDefault';

$t->property('MyProperty');
throws_ok { $t->property('foo bar!') } qr/alphanumeric/, 'PropertyName must be alphanumeric';
throws_ok { $t->property(undef) } qr/alphanumeric/,      'PropertyName must not be undef';
throws_ok { $t->property('') } qr/alphanumeric/,         'PropertyName must have length';

$t->version(5.1);
is( ref $t->version, 'version', 'Coerced version from number' );

$t->version('5.1.2');
is( ref $t->version, 'version', 'Coerced version from string' );

$t->version('v5.1.2');
is( ref $t->version, 'version', 'Coerced version from v-string' );

$t->pkg('Foo~0.01');
is( ref $t->pkg,      'Pinto::Target::Package', 'Coerced PackageSpec from string' );
is( $t->pkg->name,    'Foo',                'PackageSpec has correct name' );
is( $t->pkg->version, '0.01',               'PackageSpec has correct version' );

$t->dist('Author/subdir/Dist-1.0.tar.gz');
is( ref $t->dist, 'Pinto::Target::Distribution', 'Coerced DistributionSpec from string' );
is( $t->dist->author, 'AUTHOR', 'DistributionSpec has correct author' );
is_deeply( $t->dist->subdirs, ['subdir'], 'DistribiutionsSpec has correct subdirs' );
is( $t->dist->archive, 'Dist-1.0.tar.gz', 'DistribiutionsSpec has correct archive' );

$t->targets('author/subdir/Dist-1.0.tar.gz');
is( ref $t->targets, 'ARRAY', 'Coerced ArrayRef from string' );
is( ref $t->targets->[0], 'Pinto::Target::Distribution', 'Coereced DistributionSpec from string' );

$t->targets( [ 'Foo~1.2', 'author/subdir/Dist-1.0.tar.gz' ] );
is( ref $t->targets->[0], 'Pinto::Target::Package',      'Coerced PackageSpec in array' );
is( ref $t->targets->[1], 'Pinto::Target::Distribution', 'Coereced DistributionSpec in array' );

$t->targets( ['Foo'] );
is( ref $t->targets->[0], 'Pinto::Target::Package', 'Coerced PackageSpec in array' );

$t->revision('AA-AA');
is( $t->revision, 'aa-aa', 'Coerced RevisionID to lowercase' );
throws_ok { $t->revision('gh123') } qr/hexadecimal/, 'RevisionID must be hex';
throws_ok { $t->revision('abc') } qr/hexadecimal/,   'RevisionID must be at least 4 chars';

lives_ok { $t->color('blue') };
lives_ok { $t->color('dark red') };
dies_ok { $t->color('foo bar') } 'Invalid color thorws exception';
dies_ok { $t->color(undef) } 'undef color thorws exception';

lives_ok { $t->colorset( [qw(red blue green)] ) };
dies_ok { $t->colorset( [qw(red blue)] ) } 'Colorset needs 3 colors';
dies_ok { $t->colorset( [qw(a b c)] ) } 'Colorset must be valid colors';
dies_ok { $t->colorset(undef) };
dies_ok { $t->colorset( [] ) };

lives_ok { $t->diffstyle('concise') } 'Valid DiffStyle';
lives_ok { $t->diffstyle('detailed') } 'Valid DiffStyle';
dies_ok { $t->diffstyle('pretty') } 'Invalid DiffStyle';

#-----------------------------------------------------------------------------

done_testing;
