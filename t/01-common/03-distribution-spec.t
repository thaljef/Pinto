#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::DistributionSpec;

#------------------------------------------------------------------------------

subtest string_constructor => sub {

    my $spec = Pinto::DistributionSpec->new('Author/subdir/Foo-1.2.tar.gz');
    is $spec->author,  'AUTHOR',                            'author attribute';
    is $spec->archive, 'Foo-1.2.tar.gz',                    'archive attribute';
    is $spec->path,    'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz', 'Constructed path';
    is "$spec", 'AUTHOR/subdir/Foo-1.2.tar.gz', 'Stringified object';

};

#------------------------------------------------------------------------------

subtest hash_constructor => sub {

    my $spec = Pinto::DistributionSpec->new(
        author  => 'Author',
        subdirs => [qw(foo bar)],
        archive => 'Foo-1.2.tar.gz'
    );

    is $spec->author,  'AUTHOR',                             'author attribute';
    is $spec->archive, 'Foo-1.2.tar.gz',                     'archive attribute';
    is $spec->path,    'A/AU/AUTHOR/foo/bar/Foo-1.2.tar.gz', 'Constructed path';
    is "$spec", 'AUTHOR/foo/bar/Foo-1.2.tar.gz', 'Stringified object';

};

#------------------------------------------------------------------------------

{

    throws_ok { Pinto::DistributionSpec->new('AUTHOR/') } qr{Invalid distribution spec}, 'Invalid dist spec';

    throws_ok { Pinto::DistributionSpec->new('/Foo-1.2.tar.gz') } qr{Invalid distribution spec}, 'Invalid dist spec';

    throws_ok { Pinto::DistributionSpec->new('Foo-1.2.tar.gz') } qr{Invalid distribution spec}, 'Invalid dist spec';

    throws_ok { Pinto::DistributionSpec->new('') } qr{Invalid distribution spec}, 'Empty dist spec';

}

#------------------------------------------------------------------------------

done_testing;
