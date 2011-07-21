package App::Pinto::Command::list;

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

sub opt_spec {
    return (
        [ "index:s"  => 'List the MASTER|LOCAL|REMOTE index' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opt, $args) = @_;
    my $requested_type = $opt->{type} || 'MASTER';
    my %valid_types = map { $_ => 1 } qw(MASTER LOCAL REMOTE);
    $self->usage_error('--index is one of ' . join '|', sort keys %valid_types)
        if not defined $valid_types{$requested_type};
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
