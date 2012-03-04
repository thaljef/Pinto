package App::Pinto::Admin::Subcommand::stack::create;

# ABSTRACT: create a new stack

use strict;
use warnings;

use Pinto::Util;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(create new) }

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    print "CREATING STACK!\n";
}

#------------------------------------------------------------------------------

1;

__END__
