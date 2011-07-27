package Pinto::IndexManager;

# ABSTRACT: Manages the indexes of a Pinto repository

use Moose;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

=attr remote_index

Returns the L<Pinto::Index> that represents our copy of the
F<02packages> file from a CPAN mirror (or possibly another Pinto
repository).  This index will include the latest versions of all the
packages on the mirror.

=cut

has 'remote_index' => (
    is             => 'ro',
    isa            => 'Pinto::Index',
    builder        => '__build_remote_index',
    init_arg       => undef,
    lazy           => 1,
);

=attr local_index

Returns the L<Pinto::Index> that represents the F<02packages> file for
your local packages.  This index will include only those packages that
you've locally added to the repository.

=cut

has 'local_index'   => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '__build_local_index',
    init_arg        => undef,
    lazy            => 1,
);

=attr master_index

Returns the L<Pinto::Index> that is the logical combination of
packages from both the remote and local indexes.  See the L<"RULES">
section below for information on how the indexes are combined.

=cut

has 'master_index'  => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '__build_master_index',
    init_arg        => undef,
    lazy            => 1,
);

#------------------------------------------------------------------------------
# Builders

sub __build_remote_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.remote.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_local_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.local.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_master_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_index {
    my ($self, %args) = @_;

    my $local = $self->config()->get_required('local');
    my $index_file = file($local, 'modules', $args{file});
    $self->log->debug("Reading index $index_file");

    return Pinto::Index->new(file => $index_file);
}

#------------------------------------------------------------------------------

sub _rebuild_master_index {
    my ($self) = @_;


    # Do this first, to kick lazy builders which also causes
    # validation on the configuration.  Then we can log...
    $self->master_index()->clear();

    $self->log()->debug("Building master index");

    $self->master_index()->add( @{$self->remote_index()->packages()} );
    $self->master_index()->merge( @{$self->local_index()->packages()} );

    $self->master_index()->write();

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__
