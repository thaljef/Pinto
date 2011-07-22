package App::Pinto::Command::verify;

# ABSTRACT: Verify that all the indexed archives are present

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------


sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error("Arguments are not allowed") if @{ $args };
}

#------------------------------------------------------------------------------

sub execute {
    $DB::single = 1;
    my ($self, $opts, $args) = @_;
    $self->pinto()->verify();
    # TODO: exit with status 1 if not verified!
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
