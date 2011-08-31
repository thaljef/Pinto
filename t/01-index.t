#!perl

use strict;
use warnings;
use Test::More (tests => 12);

use Path::Class;
use FindBin qw($Bin);
use lib dir($Bin, 'lib')->stringify();

use Pinto::Index;
use Pinto::Package;

#-----------------------------------------------------------------------------

my $logger = Pinto::Logger->new();
my $index = Pinto::Index->new(logger => $logger);

#-----------------------------------------------------------------------------
# Adding...

$index->add( mkpkg('Foo') );
is($index->package_count(), 1,
   'Added one package');

$index->add( mkpkg('Foo', undef, '2.0') );
is($index->package_count(), 1,
   'Added same package again');
is($index->find(package=>'Foo')->version(), '2.0',
   'Adding same package again overrides original');

$index->clear();
$index->add( mkpkg(['Bar', 'Baz']) );
is($index->package_count(), 2,
   'Added two packages at the same time');

#-----------------------------------------------------------------------------
# Removing by package...

$index->remove( 'Bar' );
is($index->package_count(), 0,
   'Removed a package');
is($index->find(package=>'Bar'), undef,
   'Package Bar is removed');
is($index->find(package=>'Baz'), undef,
   'Package Baz is removed');

#-----------------------------------------------------------------------------
# Removing by dist...


$index->add( mkpkg(['Bar', 'Baz']) );
is($index->package_count(), 2,
   'Added two packages at the same time');

$index->remove_dist('C/CH/CHAUCER/Bar-1.0.tar.gz');
is($index->package_count(), 0,
   'Both packages are gone now');


#-----------------------------------------------------------------------------
# Merging...

$index->clear();
$index->add( mkpkg(['Eenie', 'Meenie']) );
$index->add( mkpkg(['Meenie', 'Moe'], undef, '2.0') );

is($index->find(package=>'Meenie')->version(), '2.0',
    'Incumbent package replaced with mine');

is($index->find(package=>'Eenie'), undef,
    'Extra incumbent packages are gone');

is($index->find(package=>'Moe')->version(), '2.0',
    'New package is in place');


#-----------------------------------------------------------------------------

sub mkpkg {
    my ($pkg_names, $file, $version, $author) = @_;

    $version ||= '1.0';
    $pkg_names = [ $pkg_names ] if ref $pkg_names ne 'ARRAY';
    $file    ||= $pkg_names->[0] . "-$version.tar.gz";
    $author  ||= 'CHAUCER';

    my $authdir = Pinto::Util::author_dir($author);
    my $dist = Pinto::Distribution->new(location => "$authdir/$file");

    for my $pkg_name ( @{ $pkg_names } ) {
      my $pkg = Pinto::Package->new( name    => $pkg_name,
                                     version => $version,
                                     dist    => $dist, );

      $dist->add_packages($pkg);
    }

    return @{ $dist->packages() };
}
