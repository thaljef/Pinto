# ABSTRACT: Global variables used across the Pinto utilities

package Pinto::Globals;

use strict;
use warnings;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

## no critic qw(PackageVars);
our $current_utc_time     = undef;
our $current_time_offset  = undef;
our $current_username     = undef;
our $current_author_id    = undef;
our $is_interactive       = undef;

#------------------------------------------------------------------------------
1;

__END__
