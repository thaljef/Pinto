# ABSTRACT: Global variables used across the Pinto utilities

package Pinto::Globals;

use strict;
use warnings;

use LWP::UserAgent;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

## no critic qw(PackageVars);
our $current_utc_time    = undef;
our $current_time_offset = undef;
our $current_username    = undef;
our $current_author_id   = undef;
our $is_interactive      = undef;

#------------------------------------------------------------------------------
# TODO: Decide how to expose this

our $UA = LWP::UserAgent->new(
	agent      => 'Pinto/' . __PACKAGE__->VERSION || '?',
   	env_proxy  => 1,
   	keep_alive => 5,
);

#------------------------------------------------------------------------------
1;

__END__
