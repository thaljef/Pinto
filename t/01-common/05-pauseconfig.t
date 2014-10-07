#!perl

use strict;
use warnings;

use Test::More;
use Test::Warn;

use File::Temp;

sub write_temp_file {
    my ($content) = @_;

    my $temp = File::Temp->new;
    $temp->autoflush(1);
    print $temp $content;

    return $temp;
}

note "Creating Local::PauseConfig class for testing";
{

    package Local::PauseConfig;
    use Moose;
    with qw(Pinto::Role::PauseConfig);
}

note "Test a pauserc file with the non_interactive flag set";
{
    my $pauserc = write_temp_file(<<'TEXT');
user 	 	SOMEUSER

mailto		somebody@example.com

non_interactive
TEXT

    my $obj = Local::PauseConfig->new( pauserc => $pauserc->filename );

    warnings_are {
        is_deeply $obj->pausecfg, { user => "SOMEUSER", mailto => 'somebody@example.com' };
    }
    [];
}

done_testing;
