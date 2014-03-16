# ABSTRACT: Update packages to latest versions

package Pinto::Action::Update;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;

use Pinto::Util qw(throw);
use Pinto::Types qw(PackageTargetList);
use Pinto::Target::Package;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => PackageTargetList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    default  => sub { [] },
    coerce   => 1,
);

has all => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has roots => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has no_fail => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller );

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    $self->stack->assert_not_locked;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ( @successful, @failed );

    my $stack = $self->stack;
    my @targets = $self->compute_targets;

    for my $target ( @targets ) {

        if ($target->version) {
            $self->warning("Ignoring version specification on target $target");
            $target = $target->unversioned;
        }

        try {
            $self->repo->svp_begin;
            my $dist = $self->update($target);
            push @successful, $dist if $dist;
        }
        catch {
            throw $_ unless $self->no_fail;
            $self->result->failed( because => $_ );

            $self->repo->svp_rollback;

            $self->error($_);
            $self->error("Target $target failed...continuing anyway");
            push @failed, $target;
        }
        finally {
            my ($error) = @_;
            $self->repo->svp_release unless $error;
        };
    }

    $self->chrome->progress_done;

    return @successful;
}

#------------------------------------------------------------------------------

sub compute_targets {
    my ($self) = @_;

    my $stack = $self->stack;

    return map {$_->package->as_target->unversioned} $stack->head->registrations
        if $self->all;

    return map {$_->main_module->as_target->unversioned} $stack->roots
        if $self->roots;

    return $self->targets
        if $self->targets;

    throw "No targets specified";
}


#------------------------------------------------------------------------------
# TODO: Should we only update packages from foreign dists?
# TODO: Skip pinned targets unless --force
# TODO: Should pins be preserved?


sub update {
    my ($self, $target) = @_;

    my $pkg_name = $target->name;
    my $stack    = $self->stack;

    throw ("Package $pkg_name is not on stack $stack")
        unless my $reg = $stack->head->registrations->find({package_name => $pkg_name});

    if ($reg->is_pinned && !$self->force) {
        $self->notice("Skipping pinned package $pkg_name");
        return;
    }

    if ($reg->distribution->is_local && !$self->all) {
        $self->notice("Skipping local package $pkg_name");
        return;
    }

    my $current = $reg->package;
    my $latest  = $self->repo->locate(target => $target);

    if (!$latest) {
        my $level = $reg->distribution->is_local ? 'notice' : 'warning';
        $self->$level("No upstream version of $pkg_name was found");
        return;
    }

    my $latest_version = $latest->{version};
    my $current_version = $current->version;

    if ($latest_version <= $current_version) {
        $self->notice( "Package $pkg_name~$current_version is up to date");
        return;
    }

    if ($reg->is_pinned && $self->force) {
        $self->notice("Unpinning $pkg_name to force update");
        $reg->distribution->unpin(stack => $stack);
    }

    # Finally, we update...
    $self->notice("Updating $pkg_name to $latest_version on stack $stack");
    my %target_args = (name => $pkg_name, version => $latest_version);
    my $new_target = Pinto::Target::Package->new(%target_args);
    return $self->pull(target => $new_target);

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
