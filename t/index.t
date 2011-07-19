#!perl

use strict;
use warnings;

use Pinto::Index;
use Pinto::Package;

use Test::More (tests => 6);

#-----------------------------------------------------------------------------

my $foo = Pinto::Package->new(name => 'Foo', version => '1.0', file => 'Dist.tar.gz');
my $bar = Pinto::Package->new(name => 'Bar', version => '1.0', file => 'Dist.tar.gz');
my $packages_by_name = { $foo->name() => $foo, $bar->name() => $bar };
my $packages_by_file = { $foo->file() => [$foo, $bar] };

my $index = Pinto::Index->new();
$index->add($foo, $bar);

is($index->package_count(), 2, 'Package count after adding');
is_deeply($index->packages_by_name(), $packages_by_name, 'Packages by name');
is_deeply($index->packages_by_file(), $packages_by_file, 'Packages by file');

#-----------------------------------------------------------------------------

my $my_foo = Pinto::Package->new(name => 'Foo', version => '1.1', file => 'MyDist.tar.gz');
$packages_by_name = { $my_foo->name() => $my_foo};
$packages_by_file = { $my_foo->file() => [$my_foo] };

$index->merge($my_foo);

is($index->package_count(), 1, 'Package count after merging');
is_deeply($index->packages_by_name(), $packages_by_name, 'Packages by name');
is_deeply($index->packages_by_file(), $packages_by_file, 'Packages by file');
