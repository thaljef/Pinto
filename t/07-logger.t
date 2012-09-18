#!perl

use strict;
use warnings;

use Test::More;

use IO::String;
use File::Temp;
use Path::Class;
use Log::Dispatch::Handle;

use Pinto::Logger;

#-----------------------------------------------------------------------------
{
    my $temp     = File::Temp->newdir();
    my $root     = dir($temp->dirname);
    my $logger   = Pinto::Logger->new(root => $root, username => 'foo');
    my $log_file = $root->subdir( qw(.pinto log) )->file('pinto.log');

    $logger->error('error');     # Logged
    $logger->warning('warning'); # Logged
    $logger->notice('notice');   # Logged
    $logger->info('info');       # Not Logged
    $logger->debug('info');      # Not Logged

    ok -e $log_file, "log file exists at $log_file";

    my @lines = $log_file->slurp;
    is scalar @lines, 3, 'log file contains correct number of messages';

    like $lines[-1], qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} foo NOTICE: notice$/,
        'logged message is correct';
}

#-----------------------------------------------------------------------------
{
    my $temp     = File::Temp->newdir;
    my $root     = dir($temp->dirname);
    my $logger   = Pinto::Logger->new(root => $root);

    my $buffer = '';
    my $handle = IO::String->new(\$buffer);
    my $output = Log::Dispatch::Handle->new( min_level => 'debug',
                                             handle    => $handle );

    $logger->add_output($output);
    $logger->debug('debug');

    is $buffer, 'debug', 'Logger wrote to custom output object';
}

#-----------------------------------------------------------------------------

done_testing;
