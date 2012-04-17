
# ABSTRACT: Report statistics about the repository
package Pinto::Action::Statistics;

use Moose;

use Pinto::Statistics;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Interface::Action::Statistics );

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stats = Pinto::Statistics->new( db => $self->repos->db() );
    print { $self->out() } $stats->to_formatted_string();

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
