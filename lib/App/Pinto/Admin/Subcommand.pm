package App::Pinto::Admin::Subcommand;

# ABSTRACT: Base class for pinto-admin subcommands

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

sub command_namespace_prefix {
    return __PACKAGE__;
}

#-----------------------------------------------------------------------------
1;

__END__
