#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Logger;

#-----------------------------------------------------------------------------

{
my $buffer = '';
my $logger = Pinto::Logger->new(out => \$buffer, noscreen => 1);

$logger->debug("debug");
is($buffer, '', 'debug message not logged');

$logger->note("note");
is($buffer, '', 'note message not logged');

$logger->info("info");
like($buffer, qr/info/, 'info message not logged');

$logger->whine("whine");
like($buffer, qr/whine/, 'whine message was logged');
}

#-----------------------------------------------------------------------------

{
my $quiet_buffer = '';
my $quiet_logger = Pinto::Logger->new( verbose  => 3,
                                       quiet    => 1,
                                       noscreen => 1,
                                       out      => \$quiet_buffer );

$quiet_logger->debug("debug");
is($quiet_buffer, '', 'debug message not logged when quiet');

$quiet_logger->note("note");
is($quiet_buffer, '', 'note message not logged when quiet');

$quiet_logger->info("info");
is($quiet_buffer, '', 'info message not logged when quiet');

$quiet_logger->whine("whine");
is($quiet_buffer, '', 'whine message not logged when quiet');
}

#-----------------------------------------------------------------------------

{
my $loud_buffer = '';
my $loud_logger = Pinto::Logger->new( verbose  => 3,
                                      noscreen => 1,
                                      out      => \$loud_buffer );

$loud_logger->debug("debug");
like($loud_buffer, qr/debug/, 'debug message logged when loud');

$loud_logger->info("note");
like($loud_buffer, qr/note/, 'note message logged when loud');

$loud_logger->info("info");
like($loud_buffer, qr/info/, 'info message logged when loud');

$loud_logger->whine("whine");
like($loud_buffer, qr/whine/, 'whine message logged when loud');
}

#-----------------------------------------------------------------------------
{

my $prefix_buffer = '';
my $prefix_logger = Pinto::Logger->new( noscreen   => 1,
                                        out_prefix => 'PREFIX: ',
                                        out        => \$prefix_buffer );

$prefix_logger->whine("whine");
like($prefix_buffer, qr/^PREFIX: whine/, 'logged message with prefix');

}
#-----------------------------------------------------------------------------
done_testing();
