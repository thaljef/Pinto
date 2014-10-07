# ABSTRACT: Role for actions that are transactional

package Pinto::Role::Transactional;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;

use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

requires qw( execute repo );

#------------------------------------------------------------------------------

around execute => sub {
    my ( $orig, $self, @args ) = @_;

    $self->repo->txn_begin;

    my $result = try { $self->$orig(@args); $self->repo->txn_commit }
               catch { $self->repo->txn_rollback; throw $_ };

    return $self->result;
};

#------------------------------------------------------------------------------
1;

__END__
