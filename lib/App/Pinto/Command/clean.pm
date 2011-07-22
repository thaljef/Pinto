package App::Pinto::Command::clean;

# ABSTRACT: Clean files that are no longer in the index

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error('Arguments are not allowed') if @{ $args };
}

#------------------------------------------------------------------------------

sub execute {
    $DB::single = 1;
    my ($self, $opts, $args) = @_;
    $self->pinto()->list();
    return 0;
}

#------------------------------------------------------------------------------

1;

__END__
