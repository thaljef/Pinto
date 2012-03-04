package App::Pinto::Admin::Subcommand::stack::remove;

# ABSTRACT: remove a stack

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(remove rm delete del) }

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    print "REMOVING STACK!\n";
}

#------------------------------------------------------------------------------

1;

__END__
