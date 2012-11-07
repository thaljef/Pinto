# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

use Try::Tiny;

use Pinto::CommitMessage;
use Pinto::Exception qw(throw);
use Pinto::Util qw(is_interactive);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has message => (
    is        => 'ro',
    isa       => Str,
);

has use_default_message => (
    is         => 'ro',
    isa        => Bool,
    default    => 0,
);

#------------------------------------------------------------------------------

requires qw( execute message_primer );

#------------------------------------------------------------------------------

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repo->db->txn_begin;

    my $result = try   { $self->$orig(@args) }
                 catch { $self->repo->db->txn_rollback; die $_ };

    if ($self->dryrun) {
        $self->notice('Dryrun -- rolling back database');
        $self->repo->db->txn_rollback;
        $self->repo->clean_files;
    }
    elsif (not $result->made_changes) {
        $self->notice('No changes were actually made');
        $self->repo->db->txn_rollback;
    }
    else {
        $self->debug('Committing changes to database');
        $self->repo->db->txn_commit;
    }

    return $self->result;
};

#------------------------------------------------------------------------------

sub edit_message {
    my ($self, %args) = @_;

    my $stacks = $args{stacks} || [];
    my $primer = $args{primer} || $self->message_primer || '';

    return $self->message if $self->message;
    return $primer if $self->use_default_message;
    return $primer if not is_interactive;

    my $message = Pinto::CommitMessage->new(stacks => $stacks, primer => $primer)->edit;
    throw 'Aborting due to empty commit message' if $message !~ /\S+/;

    return $message;
}

#------------------------------------------------------------------------------
1;

__END__
