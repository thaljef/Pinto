package App::Pinto::Admin::Subcommand::stack::merge;

# ABSTRACT: merge two stacks together

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    print "MERGING STACK!\n";
}

#------------------------------------------------------------------------------

1;

__END__
