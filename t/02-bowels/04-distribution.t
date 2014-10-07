#!perl

use strict;
use warnings;

use Test::More;

use Path::Class;

use lib 't/lib';
use Pinto::Tester::Util qw(make_dist_obj);

#-----------------------------------------------------------------------------

{
    my $dist = make_dist_obj(
        author  => 'FOO',
        archive => 'Bar-1.2.tar.gz'
    );

    is( $dist->author,   'FOO',                     'dist author' );
    is( $dist->archive,  'Bar-1.2.tar.gz',          'dist archive' );
    is( $dist->source,   'LOCAL',                   'Source defaults to q{LOCAL}' );
    is( $dist->name,     'Bar',                     'dist name' );
    is( $dist->vname,    'Bar-1.2',                 'dist name' );
    is( $dist->version,  '1.2',                     'dist version' );
    is( $dist->is_local, 1,                         'is_local is true when origin eq q{LOCAL}' );
    is( $dist->is_devel, q{},                       'this is not a devel dist' );
    is( $dist->path,     'F/FO/FOO/Bar-1.2.tar.gz', 'Logical archive path' );
    is( $dist->native_path('here'), file(qw(here F FO FOO Bar-1.2.tar.gz)), 'Physical archive path, with base' );
    is( "$dist", 'FOO/Bar-1.2.tar.gz', 'Stringifies to author/archive' );
}

#-----------------------------------------------------------------------------

{
    my $dist = make_dist_obj(
        author  => 'FOO',
        archive => 'Bar-4.3_34.tgz',
        source  => 'http://remote/Bar-4.3_34.tgz'
    );

    is( $dist->source(),   'http://remote/Bar-4.3_34.tgz', 'Non-local source' );
    is( $dist->name(),     'Bar',                          'dist name' );
    is( $dist->vname(),    'Bar-4.3_34',                   'dist vname' );
    is( $dist->version(),  '4.3_34',                       'dist version' );
    is( $dist->is_local(), q{},                            'is_local is false when dist is remote' );
    is( $dist->is_devel(), 1,                              'this is a devel dist' );
}

#------------------------------------------------------------------------------

{
    my $dist = make_dist_obj(
        author  => 'AUTHOR',
        archive => 'Foo-2.0.tar.gz'
    );

    my %formats = (
        'm' => 'r',
        'h' => 'A/AU/AUTHOR/Foo-2.0.tar.gz',
        's' => 'l',
        'S' => 'LOCAL',
        'a' => 'AUTHOR',
        'd' => 'Foo',
        'D' => 'Foo-2.0',
        'V' => '2.0',
        'u' => 'UNKNOWN',
    );

    while ( my ( $placeholder, $expected ) = each %formats ) {
        my $got = $dist->to_string("%$placeholder");
        is( $got, $expected, "Placeholder: %$placeholder" );
    }
}

#------------------------------------------------------------------------------

done_testing;
