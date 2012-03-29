#!perl

use strict;
use warnings;

use Test::More;

use Pinto::Logger;
use Pinto::Tester;
use Path::Class;

#-----------------------------------------------------------------------------

my $t = Pinto::Tester->new;

{
my $buffer = '';
my $logger = Pinto::Logger->new( out => \$buffer, log_dir => undef, log_file => undef, root => $t->root);

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
my $quiet_logger = Pinto::Logger->new( verbose => 3,
                                       quiet   => 1,
                                       out     => \$quiet_buffer,
                                       log_dir => undef,
                                       log_file => undef,
                                       root => $t->root,
                                     );

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
my $loud_logger = Pinto::Logger->new( verbose => 3,
                                      out     => \$loud_buffer,
                                      log_dir => undef,
                                      log_file => undef,
                                      root => $t->root,
                                    );

$loud_logger->debug("debug");
like($loud_buffer, qr/debug/, 'debug message logged when loud');

$loud_logger->info("note");
like($loud_buffer, qr/note/, 'note message logged when loud');

$loud_logger->info("info");
like($loud_buffer, qr/info/, 'info message logged when loud');

$loud_logger->whine("whine");
like($loud_buffer, qr/whine/, 'whine message logged when loud');
}

{
    # file logging
    my $dir = $t->root->subdir('log');
    my $file = file($dir, 'pinto.log');
    my $file_logger = Pinto::Logger->new(verbose => 3,
                                         noscreen => 1,
                                         log_dir => $dir,
                                         log_file => $file,
                                         root => $t->root,
                                        );

    $file_logger->debug("debug");

    my $fh = $file->openr;
    my @lines = <$fh>;
    is(@lines, 1, 'one line has been logged');
    like(
        $lines[0],
        qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2} debug$/,
        'logged message is correct',
    );
}

#-----------------------------------------------------------------------------

done_testing();
