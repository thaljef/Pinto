#!perl

use strict;
use warnings;
use version;

use Test::More;

use Pinto::Target::Package;

#------------------------------------------------------------------------------
{

    my $target = Pinto::Target::Package->new('Foo~1.2');
    is $target->name,    'Foo', 'Parsed package name from string';
    is $target->version, '1.2', 'Parsed package version from string';
    is "$target", 'Foo~1.2', 'Stringified Target object';

}

#------------------------------------------------------------------------------
{

    my $target = Pinto::Target::Package->new('Foo');
    is $target->name,    'Foo', 'Parsed package name from string';
    is $target->version, '0',   'Parsed package version from string without version';
    is "$target", 'Foo~0', 'Stringified Target object';

}

#------------------------------------------------------------------------------

{

    my $target = Pinto::Target::Package->new( name => 'Foo', version => 1.2 );
    is $target->name,    'Foo', 'Constructor with normal name attribute';
    is $target->version, '1.2', 'Constructor with normal version version';
    is "$target", 'Foo~1.2', 'Stringified Target object';

}

#------------------------------------------------------------------------------
{

    my %tests = (
        ''   => [
            ['1.2' => 1],
            [undef => 1],
            [0     => 1],
        ],
        'undef' => [
            ['1.2' => 1],
            [undef => 1],
            [0     => 1],
        ],
        '~1.2' => [
            ['1.2' => 1],
            ['1.3' => 1],
            ['1.1' => 0],
            [undef => 0],
            [0     => 0],
        ],
        '@1.2' => [
            ['1.1' => 0],
            ['1.2' => 1],
            ['1.3' => 0],
            ['1.1' => 0],
            [undef => 0],
            [0     => 0],
        ],
        ' 1.2  ' => [
            ['1.2' => 1],
            ['1.3' => 1],
            ['1.1' => 0],
            [undef => 0],
            [0     => 0],
        ],
        '~1.2, <= 1.9, != 1.5' => [
            ['1.1' => 0],
            ['1.2' => 1],
            ['1.5' => 0],
            ['1.9' => 1],
            ['2.0' => 0],
            [undef => 0],
            [0     => 0],
        ]
    );

    while ( my ($req, $cases) = each %tests ) {
        for my $case ( @$cases ) {
            my ($version, $expect) = @{$case};
            my $target = Pinto::Target::Package->new("Foo::Bar$req");
            my $got = $target->is_satisfied_by($version);
            ok $got, "Target $target should be satisfied by $version" if $expect;
            ok !$got, "Target $target should not be satisfied by $version" if not $expect;
        }
    }
}

#------------------------------------------------------------------------------

{

    # Module::Build first introduced into core in perl 5.9.4
    # Module::Build was first upgraded to 0.038 in perl 5.13.11

    my $target = Pinto::Target::Package->new( name => 'Module::Build', version => 0.38 );
    is $target->is_core( in => 'v5.6.1' ),  0, "$target is not in perl 5.6.1";
    is $target->is_core( in => 'v5.10.1' ), 0, "$target is not in perl 5.10.1";
    is $target->is_core( in => 'v5.14.2' ), 1, "$target is in perl 5.14.2";

    local $] = 5.013011;
    is $target->is_core, 1, "$target is in *this* perl, pretending we are $]"

}

#------------------------------------------------------------------------------

done_testing;
