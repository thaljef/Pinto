#!perl

use strict;
use warnings;

use Test::More (tests => 6);

use Pinto::Logger;

#-----------------------------------------------------------------------------

my $buffer = '';
my $logger = Pinto::Logger->new( repos => 'nowhere',
                                   out => \$buffer );

$logger->debug("debug");
is($buffer, '', 'debug message not logged');

$logger->info("info");
like($buffer, qr/info/, 'info message was logged');

$logger->whine("whine");
like($buffer, qr/info/, 'whine message was logged');

#-----------------------------------------------------------------------------

my $quiet_buffer = '';
my $quiet_logger = Pinto::Logger->new( repos   => 'nowhere',
                                       verbose => 3,
                                       quiet   => 1,
                                       out     => \$quiet_buffer );

$logger->debug("debug");
is($quiet_buffer, '', 'debug message not logged when quiet');

$logger->info("info");
is($quiet_buffer, '', 'info message not logged when quiet');

$logger->whine("fatal");
is($quiet_buffer, '', 'whine message not logged when quiet');
