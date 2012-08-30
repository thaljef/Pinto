# ABSTRACT: Run Actions outside of a transaction

package Pinto::Runner::NonTransactional;

use Moose;

use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw(Pinto::Runner);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

augment run => sub {
  my ($self, $action) = @_;

    $self->repos->lock_shared;

    my $result = try   { $action->execute }
                 catch { $self->repos->unlock; die $_ };

    return $result;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
