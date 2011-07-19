use strict;
use warnings;

use Pinto::UserAgent;

my $ua = Pinto::UserAgent->new();
$ua->mirror('this', 'that');
