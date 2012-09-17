# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has message => (
    is      => 'ro',
    isa     => Str,
    default => '',
);

#------------------------------------------------------------------------------

requires qw( execute );

#------------------------------------------------------------------------------

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repos->db->txn_begin;

    my $result = try   { $self->$orig(@args) }
                 catch { $self->repos->db->txn_rollback; die $_ };

    if (not $result->made_changes) {
        $self->notice('No changes were made');
        $self->repos->db->txn_rollback;
    }
    elsif ($self->dryrun) {
        $self->notice('Dryrun -- rolling back database');
        $self->repos->db->txn_rollback;
    }
    else {
        $self->debug('Committing changes to database');
        $self->repos->db->txn_commit;
    }

    return $self->result;
};

#------------------------------------------------------------------------------
1;

__END__
