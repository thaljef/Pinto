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

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repos->db->schema->txn_begin;

    my $result = try  {

        my $res = $self->$orig(@args);

        if ($self->dryrun) {
            $self->notice('Dryrun -- rolling back database');
            $self->repos->db->schema->txn_rollback;
        }
        elsif ( not $res->made_changes ) {
            $self->notice('No changes were made');
            $self->repos->db->schema->txn_rollback;
        }
        else {
            $self->repos->db->schema->txn_commit;
        }

        $res; # returned from try{}
    }
    catch {
        $self->repos->db->schema->txn_rollback;
        die $_;        ## no critic qw(Carping)
    };

    return $self->result;
};

#------------------------------------------------------------------------------
# TODO: When we support real revision history, make the message
# attribute required whenever the dryrun attribute is false.
# ------------------------------------------------------------------------------

1;

__END__
