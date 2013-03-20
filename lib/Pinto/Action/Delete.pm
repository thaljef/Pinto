# ABSTRACT: Delete archives from the repository

package Pinto::Action::Delete;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(throw);
use Pinto::Types qw(DistSpecList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has targets   => (
    isa      => DistSpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has force => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    for my $target ( $self->targets ) {

        my $dist = $self->repo->get_distribution(spec => $target);
        
        throw "Distribution $target is not in the repository" if not defined $dist;

        $self->notice("Deleting $dist from the repository");
        
        $self->repo->delete_distribution(dist => $dist, force => $self->force);
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
