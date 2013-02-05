# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods (autoclean => 1);

use Try::Tiny;

use Pinto::CommitMessage;
use Pinto::Exception qw(throw);
use Pinto::Util qw(is_interactive interpolate);

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

has use_default_message => (
    is         => 'ro',
    isa        => Bool,
    default    => 0,
);

#------------------------------------------------------------------------------

requires qw( execute message_title );

#------------------------------------------------------------------------------

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repo->db->schema->txn_begin;

    my $result = try   { $self->$orig(@args) }
                 catch { $self->repo->db->schema->txn_rollback; die $_ };

    if ($self->dryrun) {
        $self->notice('Dryrun -- rolling back database');
        $self->repo->db->schema->txn_rollback;
        $self->repo->clean_files;
    }
    elsif (not $result->made_changes) {
        $self->notice('No changes were actually made');
        $self->repo->db->schema->txn_rollback;
    }
    else {
        $self->debug('Committing changes to database');
        $self->repo->db->schema->txn_commit;
    }

    return $self->result;
};

#------------------------------------------------------------------------------

sub edit_message {
    my ($self, %args) = @_;

    my $stack  =  $args{stack};
    my $title  =  $args{title} || $self->message_title || '';

    return interpolate($self->message)
        if $self->has_message and $self->message =~ /\S+/;

    return $title
        if $self->has_message and $self->message !~ /\S+/;

    return $title
        if $self->use_default_message;

    return $title
        if not is_interactive;

    my $message = Pinto::CommitMessage->new(stack => $stack, title => $title)->edit;
    throw 'Aborting due to empty commit message' if $message !~ /\S+/;

    return $message;
}

#------------------------------------------------------------------------------
1;

__END__
