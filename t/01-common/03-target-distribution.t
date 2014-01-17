#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Target::Distribution;

#------------------------------------------------------------------------------

subtest string_constructor => sub {

    my $target = Pinto::Target::Distribution->new('Author/subdir/Foo-1.2.tar.gz');
    is $target->author,  'AUTHOR',                            'author attribute';
    is $target->archive, 'Foo-1.2.tar.gz',                    'archive attribute';
    is $target->path,    'A/AU/AUTHOR/subdir/Foo-1.2.tar.gz', 'Constructed path';
    is "$target", 'AUTHOR/subdir/Foo-1.2.tar.gz', 'Stringified object';

};

#------------------------------------------------------------------------------

subtest hash_constructor => sub {

    my $target = Pinto::Target::Distribution->new(
        author  => 'Author',
        subdirs => [qw(foo bar)],
        archive => 'Foo-1.2.tar.gz'
    );

    is $target->author,  'AUTHOR',                             'author attribute';
    is $target->archive, 'Foo-1.2.tar.gz',                     'archive attribute';
    is $target->path,    'A/AU/AUTHOR/foo/bar/Foo-1.2.tar.gz', 'Constructed path';
    is "$target", 'AUTHOR/foo/bar/Foo-1.2.tar.gz', 'Stringified object';

};

#------------------------------------------------------------------------------

{

    throws_ok { Pinto::Target::Distribution->new('AUTHOR/') } qr{Invalid distribution target}, 'Invalid dist target';

    throws_ok { Pinto::Target::Distribution->new('/Foo-1.2.tar.gz') } qr{Invalid distribution target}, 'Invalid dist target';

    throws_ok { Pinto::Target::Distribution->new('Foo-1.2.tar.gz') } qr{Invalid distribution target}, 'Invalid dist target';

    throws_ok { Pinto::Target::Distribution->new('') } qr{Invalid distribution target}, 'Empty dist target';

}

#------------------------------------------------------------------------------

done_testing;
