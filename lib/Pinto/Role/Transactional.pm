# ABSTRACT: Role for actions that are transactional

package Pinto::Role::Transactional;

use Moose::Role;

use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

requires qw( execute repo );

#------------------------------------------------------------------------------

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repo->db->schema->txn_begin;

    my $result = try   { $self->$orig(@args); $self->repo->db->schema->txn_commit;}
                 catch { $self->repo->db->schema->txn_rollback; die $_ };

    return $self->result;
};

#------------------------------------------------------------------------------
1;

__END__
