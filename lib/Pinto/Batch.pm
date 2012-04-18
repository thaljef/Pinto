package Pinto::Batch;

# ABSTRACT: Runs a series of actions

use Moose;

use MooseX::Types::Moose qw(Str Bool);

use Carp;
use Try::Tiny;

use Pinto::BatchResult;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Loggable
         Pinto::Role::Configurable
         Pinto::Role::Attribute::username);

#------------------------------------------------------------------------------
# Attributes

has repos    => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1
);


has message => (
    is         => 'ro',
    isa        => Str,
    default    => 'No message was given',
);


has actions => (
    isa      => 'ArrayRef[Pinto::Action]',
    traits   => [ 'Array' ],
    handles  => {enqueue => 'push', dequeue => 'shift'},
    init_arg => undef,
    default  => sub { [] },
);

#------------------------------------------------------------------------------
# Public methods

=method run()

Runs all the actions in this Batch.  Returns a L<Pinto::BatchResult>.

=cut

sub run {
    my ($self) = @_;

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->warning(@_) };

    $self->repos->open_revision( username => $self->username,
                                 message  => $self->message );

    my $result = Pinto::BatchResult->new;
    while ( my $action = $self->dequeue ) {
        try   { $result->aggregate( $action->execute ) }
        catch { $self->repos->kill_revision and confess $_ };
    }

    if ($result->made_changes) {
        $self->repos->close_revision;
        $self->repos->write_index;
    }
    else {
        $self->info('No changes were made');
        $self->repos->kill_revision;
    }

    return $result;
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------
1;

__END__
