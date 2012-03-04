package App::Pinto::Admin::Subcommand::stack::copy;

# ABSTRACT: copy a stack

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(copy cp) }

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    print "COPYING STACK!\n";
}

#------------------------------------------------------------------------------

1;

__END__
