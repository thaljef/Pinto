# ABSTRACT: Run Actions inside a transaction

package Pinto::Runner::Transactional;

use Moose;

use Try::Tiny;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw(Pinto::Runner);

#------------------------------------------------------------------------------

augment run => sub {
  my ($self, $action) = @_;

    $self->repos->lock_exclusive;
    $self->repos->txn_begin;

    my $result = try {

        my $res = $action->execute;

        # TODO: Consider using a role to indicate whether an
        # Action can do a dryrun (e.g. Pinto::Role::Dryrunable)

        if ($action->can('dryrun') && $action->dryrun) {
            $self->notice('Dryrun -- rolling back');
            $self->repos->txn_rollback;
            $self->repos->clean_files;
        }
        elsif ( not $res->made_changes ) {
            $self->notice('No changes were made');
            $self->repos->txn_rollback;
        }
        else {
            $self->repos->txn_commit;
        }

        $res; # returned from try{}
    }
    catch {
        $self->repos->txn_rollback;
        $self->repos->unlock;
        die $_;        ## no critic qw(Carping)

    };

    return $result;
};

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
