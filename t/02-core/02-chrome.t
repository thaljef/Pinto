#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use Pinto::Chrome::Term;

#-----------------------------------------------------------------------------

{
    my $chrome = Pinto::Chrome::Term->new;
    is $chrome->should_render_diag(0), 1, 'Diag level 0 at default vebosity';
    is $chrome->should_render_diag(1), 1, 'Diag level 1 at default vebosity';
    is $chrome->should_render_diag(2), 0, 'Diag level 2 at default vebosity';
    is $chrome->should_render_diag(3), 0, 'Diag level 3 at default vebosity';

    local $Pinto::Globals::is_interactive = 1;
    is $chrome->should_render_progress, 1, 'Show progress at default verbosity, when interactive';

    local $Pinto::Globals::is_interactive = 0;
    is $chrome->should_render_progress, 0, 'Hide progress at default verbosity, when not interactive';
}

#-----------------------------------------------------------------------------

{
    my $chrome = Pinto::Chrome::Term->new(verbose => 1);
    is $chrome->should_render_diag(0), 1, 'Diag level 0 at verbose = 1';
    is $chrome->should_render_diag(1), 1, 'Diag level 1 at verbose = 1';
    is $chrome->should_render_diag(2), 1, 'Diag level 2 at verbose = 1';
    is $chrome->should_render_diag(3), 0, 'Diag level 3 at verbose = 1';
    is $chrome->should_render_progress, 0, 'Hide progress at verbose = 1';
}

#-----------------------------------------------------------------------------

{
    my $chrome = Pinto::Chrome::Term->new(quiet => 1);
    is $chrome->should_render_diag(0), 1, 'Diag level when quiet';
    is $chrome->should_render_diag(1), 0, 'Diag level when quiet';
    is $chrome->should_render_diag(2), 0, 'Diag level when quiet';
    is $chrome->should_render_diag(3), 0, 'Diag level when quiet';
    is $chrome->should_render_progress, 0, 'Hide progress when quiet';
}

#-----------------------------------------------------------------------------

{
    local $ENV{PINTO_COLORS} = 'dark blue,  white on_red,green';

    my $chrome = Pinto::Chrome::Term->new;
    is_deeply $chrome->colors, ['dark blue', 'white on_red', 'green'], 'Parsed color list';
}

#-----------------------------------------------------------------------------

{
    throws_ok { Pinto::Chrome::Term->new(colors => []) } 
        qr/exactly three colors/, 'Too few colors';

    throws_ok { Pinto::Chrome::Term->new(colors => [0..3]) } 
        qr/exactly three colors/, 'Too many colors';

    throws_ok { Pinto::Chrome::Term->new(colors => [qw(red blue chartruse)]) } 
        qr/chartruse is not valid/, 'Invalid color';
}

#-----------------------------------------------------------------------------

{
    local $ENV{PINTO_NO_COLOR} = 1;

    my ($out, $err) = ('', '');
    my $chrome = Pinto::Chrome::Term->new(stdout => \$out, stderr => \$err);
    $chrome->error('This is diagnostic');
    $chrome->show('This is output');

    is $out, "This is output\n",     'Got stuff on output handle';
    is $err, "This is diagnostic\n", 'Got stuff on error handle';
}

#-----------------------------------------------------------------------------

done_testing;
