#!perl

use strict;
use warnings;

use Test::More (tests => 8);

use Pinto::Logger;

#-----------------------------------------------------------------------------

my $buffer = '';
my $logger = Pinto::Logger->new( out => \$buffer );

$logger->debug("debug");
is($buffer, '', 'debug message not logged');

$logger->info("info");
is($buffer, '', 'info message not logged');

$logger->whine("whine");
like($buffer, qr/whine/, 'whine message was logged');

#-----------------------------------------------------------------------------

my $quiet_buffer = '';
my $quiet_logger = Pinto::Logger->new( verbose => 3,
                                       quiet   => 1,
                                       out     => \$quiet_buffer );

$quiet_logger->debug("debug");
is($quiet_buffer, '', 'debug message not logged when quiet');

$quiet_logger->info("info");
is($quiet_buffer, '', 'info message not logged when quiet');

$quiet_logger->whine("whine");
is($quiet_buffer, '', 'whine message not logged when quiet');


#-----------------------------------------------------------------------------

my $loud_buffer = '';
my $loud_logger = Pinto::Logger->new( verbose => 2,
                                      out     => \$loud_buffer );

$loud_logger->debug("debug");
like($loud_buffer, qr/debug/, 'debug message logged when loud');

$loud_logger->info("info");
like($loud_buffer, qr/info/, 'info message logged when loud');

