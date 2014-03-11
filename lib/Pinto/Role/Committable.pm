# ABSTRACT: Role for actions that commit changes to the repository

package Pinto::Role::Committable;

use Moose::Role;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use List::MoreUtils qw(uniq);

use Pinto::Constants qw(:lock);
use Pinto::Types qw(StackName StackDefault StackObject DiffStyle);
use Pinto::Util qw(is_interactive throw is_blank is_not_blank);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Pinto::Role::Plated);

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault | StackObject,
    writer  => '_set_stack',
    default => undef,
);

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
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has diff_style => (
    is        => 'ro',
    isa       => DiffStyle,
    predicate => 'has_diff_style',
);

has lock_type => (
    is       => 'ro',
    isa      => Str,
    default  => $PINTO_LOCK_TYPE_EXCLUSIVE,
    init_arg => undef,
);

#------------------------------------------------------------------------------

requires qw( execute repo );

#------------------------------------------------------------------------------

around BUILD => sub {
    my ( $orig, $self ) = @_;

    # Inflate the stack into a real object.  As a side
    # effect, this also verifies that the stack exists.

    my $stack = $self->repo->get_stack( $self->stack );
    $self->_set_stack($stack);

    return $self->$orig;
};

#------------------------------------------------------------------------------

around execute => sub {
    my ( $orig, $self, @args ) = @_;

    $self->repo->txn_begin;
    my $stack = $self->stack->start_revision;
    local $ENV{PINTO_DIFF_STYLE} = $self->diff_style if $self->has_diff_style;

    my @ok = try { $self->$orig(@args) } catch { $self->repo->txn_rollback; throw $_ };

    if ( $self->dry_run ) {

        $stack->refresh->has_changed
            ? $self->show($stack->diff, {no_newline => 1})
            : $self->notice('No changes were made');

        $self->repo->txn_rollback;
        $self->repo->clean_files;
    }
    elsif ( $stack->refresh->has_not_changed ) {

        $self->warning('No changes were made');
        $self->repo->txn_rollback;
    }
    else {

        my $msg_title = $self->generate_message_title(@ok);
        my $msg = $self->compose_message( title => $msg_title, stack => $stack );
        $stack->commit_revision( message => $msg );

        $self->result->changed;
        $self->repo->txn_commit;
    }

    # Release the exclusive lock and just use a shared lock, since
    # we won't be writing to the repository at this point.
    $self->repo->unlock; $self->repo->lock($PINTO_LOCK_TYPE_SHARED);

    return $self->result;
};

#------------------------------------------------------------------------------

sub compose_message {
    my ( $self, %args ) = @_;

    my $title = $args{title} || '';
    my $stack = $args{stack} || throw 'Must specify a stack';
    my $diff  = $args{diff}  || $stack->diff;

    return $self->message
        if $self->has_message and is_not_blank( $self->message );

    return $title
        if $self->has_message and is_blank( $self->message );

    return $title
        if $self->use_default_message;

    return $title
        if not is_interactive;

    my $cm = $self->generate_message_template($title, $stack, $diff);
    my $message = $self->chrome->edit( $cm );
    $message =~ s/^ [#] .* $//gmsx; # Strip comments

    throw 'Aborting due to empty commit message' if is_blank($message);

    return $message;
}

#------------------------------------------------------------------------------

sub generate_message_title {
    my ( $self, @items, $extra ) = @_;

    my $class    = ref $self;
    my ($action) = $class =~ m/ ( [^:]* ) $/x;
    my $title    = "$action " . join( ', ', uniq(sort @items) ) . ( $extra ? " $extra" : '' );

    return $title;
}

#------------------------------------------------------------------------------

sub generate_message_template {
    my ( $self, $title, $stack, $diff ) = @_;

    # Prepend "#" to each line of the diff,
    # so they are treated as comments.
    $diff =~ s/^/# /gm;

    my $msg = <<"END_MESSAGE";
$title


#-------------------------------------------------------------------------------
# Please edit or amend the message above as you see fit.  The first line of the 
# message will be used as the title.  Any line that starts with a "#" will be 
# ignored.  To abort the commit, delete the entire message above, save the file, 
# and close the editor. 
#
# Changes to be committed to stack $stack:
#
$diff
END_MESSAGE

    chomp $msg;
    return $msg;
}

#------------------------------------------------------------------------------
1;

__END__
