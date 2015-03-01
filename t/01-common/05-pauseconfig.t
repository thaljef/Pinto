#!perl

use strict;
use warnings;

use Test::More;
use File::Temp;
use Pinto::Globals;

#-----------------------------------------------------------------------------

package Local::PauseConfig;
use Moose;
with qw(Pinto::Role::PauseConfig);

#-----------------------------------------------------------------------------

package main;

sub write_temp_file {
    my ($content) = @_;

    my $temp = File::Temp->new;
    $temp->autoflush(1);
    print $temp $content;

    return $temp;
}

#-----------------------------------------------------------------------------

my $pauserc = write_temp_file(<<'TEXT');
user 	 	SOMEUSER

mailto		somebody@example.com

non_interactive
TEXT

#-----------------------------------------------------------------------------

subtest 'Read from ~/.pause' => sub {
    my $obj = Local::PauseConfig->new( pauserc => $pauserc->filename );
    is_deeply $obj->pausecfg, { user => "SOMEUSER", mailto => 'somebody@example.com' };
};

#-----------------------------------------------------------------------------

subtest 'Override using current_author_id' => sub {
    local $Pinto::Globals::current_author_id = 'ME';
    my $obj = Local::PauseConfig->new( pauserc => $pauserc->filename );
    is_deeply $obj->pausecfg, {};
};

#-----------------------------------------------------------------------------

done_testing;
