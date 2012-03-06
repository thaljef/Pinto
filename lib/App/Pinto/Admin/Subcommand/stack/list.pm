package App::Pinto::Admin::Subcommand::stack::list;

# ABSTRACT: list known stacks

use strict;
use warnings;

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Subcommand';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { qw(list ls) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (
        [ 'format=s' => 'Format of the listing'       ],
        [ 'noinit'   => 'Do not pull/update from VCS' ],
    );


}

#------------------------------------------------------------------------------
sub usage_desc {
    my ($self) = @_;

    my ($command) = $self->command_names();

    my $usage =  <<"END_USAGE";
%c --root=PATH stack $command [OPTIONS]
END_USAGE

    chomp $usage;
    return $usage;
}

#------------------------------------------------------------------------------

1;

__END__
