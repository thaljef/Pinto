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

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack   = $self->stack;
    my @targets = $self->compute_targets;

    for my $target ( @targets ) {

        if ($target->version) {
            $self->warning("Ignoring version specification on target $target");
            $target = $target->unversioned;
        }

        try {
            $self->repo->svp_begin;
            my ($dist, $did_update, $did_update_prereqs) = $self->update($target);
            push @{$self->affected}, $dist if $did_update;
        }
        catch {
            throw $_ unless $self->no_fail;
            $self->result->failed( because => $_ );

            $self->repo->svp_rollback;

            $self->error($_);
            $self->error("Target $target failed...continuing anyway");
        }
        finally {
            my ($error) = @_;
            $self->repo->svp_release unless $error;
        };
    }

    $self->chrome->progress_done;

    return $self;
}

#------------------------------------------------------------------------------

sub compute_targets {
    my ($self) = @_;

    my $stack = $self->stack;

    return map {$_->main_module->as_target->unversioned} $stack->distributions
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

    my $current_dist = $reg->distribution;
    my $current_pkg  = $reg->package;

    if ($reg->is_pinned && not $self->force) {
        $self->notice("Skipping package $pkg_name because it is pinned to $current_dist");
        return ($current_dist, 0, 0);
    }

    if ($current_dist->is_local && !$self->all) {
        $self->notice("Skipping local package $pkg_name");
        return ($current_dist, 0, 0);
    }

    # Now go look for a newer version...
    my $latest_pkg = $self->repo->locate(target => $target);

    if (!$latest_pkg and !$current_dist->is_local) {
        $self->warning("No upstream version of $pkg_name was found");
        return ($current_dist, 0, 0);
    }

    my $latest_pkg_version = $latest_pkg->{version};
    my $current_pkg_version = $current_pkg->version;

    if ($latest_pkg_version <= $current_pkg_version) {
        $self->notice( "Package $pkg_name~$current_pkg_version is up to date");
        return ($current_dist, 0, 0);
    }

    # Finally, we update...
    $self->notice("Updating $pkg_name to $latest_pkg_version on stack $stack");
    my %target_args = (name => $pkg_name, version => $latest_pkg_version);
    my $new_target = Pinto::Target::Package->new(%target_args);
    return $self->pull(target => $new_target);

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
