# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);

use Try::Tiny;
use Term::EditorEdit;
use IO::Interactive qw(is_interactive);

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
    predicate => 'has_message',
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

sub edit_message {
    my ($self, %args) = @_;

    return $self->message if $self->has_message;
    $self->fatal('Must supply a commit message') if not is_interactive;

    my $primer_header = "\n\n" . '-' x 79 . "\n\n";
    my $primer = $primer_header . ($args{primer} || 'No details available');

    my $message = Term::EditorEdit->edit(document => $primer);
    $message =~ s/( \n+ -{79} \n .*)//smx;  # Strip primer

    $self->fatal('Commit message is empty.  Aborting action') if $message !~ /\S+/;

    return $message;
}

#------------------------------------------------------------------------------
1;

__END__
