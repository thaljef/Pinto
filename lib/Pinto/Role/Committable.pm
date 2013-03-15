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

has dry_run => (
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

requires qw( execute repo );

#------------------------------------------------------------------------------

around execute => sub {
    my ($orig, $self, @args) = @_;

    $self->repo->txn_begin;

    my $result = try   { $self->$orig(@args) }
                 catch { $self->repo->txn_rollback; die $_ };

    if ($self->dry_run) {
        $self->notice('Dry run -- rolling back database');
        $self->repo->txn_rollback;
        $self->repo->clean_files;
    }
    elsif (not $result->made_changes) {
        $self->notice('No changes were actually made');
        $self->repo->txn_rollback;
    }
    else {
        $self->repo->txn_commit;
    }

    return $self->result;
};

#------------------------------------------------------------------------------

sub compose_message {
    my ($self, %args) = @_;

    my $title   = $args{title} || '';
    my $stack   = $args{stack} || throw "Must specify a stack";
    my $diff    = $args{diff}  || $stack->diff;

    return interpolate($self->message)
        if $self->has_message and $self->message =~ /\S+/;

    return $title
        if $self->has_message and $self->message !~ /\S+/;

    return $title
        if $self->use_default_message;

    return $title
        if not is_interactive;

    my $cm = Pinto::CommitMessage->new(title => $title, details => $diff->to_string); 
    my $message = $cm->edit;
                                            
    throw 'Aborting due to empty commit message' if $message !~ /\S+/;

    return $message;
}

#------------------------------------------------------------------------------

sub generate_message_title {
    my ($self, @items, $extra) = @_;

    my $class    = ref $self;
    my ($action) = $class =~ m/ ( [^:]* ) $/x;
    my $title    = "$action ". join(', ', @items) . ($extra ? " $extra" : '');

    return $title;
}

#------------------------------------------------------------------------------
1;

__END__
