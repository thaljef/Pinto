# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Try::Tiny;
use Module::CoreList;

use Pinto::Util qw(itis);
use Pinto::Types qw(SpecList StackName StackDefault StackObject);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has norecurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has nofail => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $stack   = $self->repo->get_stack($self->stack);
    my @targets = $self->targets;

    while (my $target = shift @targets) {

        try   {
            $self->repo->db->schema->storage->svp_begin; 
            $self->_pull($target, $stack) 
        }
        catch {
            die $_ unless $self->nofail && @targets;

            $self->repo->db->schema->storage->svp_rollback;

            $self->error("$_");
            $self->error("$target failed...continuing anyway");
        }
        finally {
            my ($error) = @_;
            $self->repo->db->schema->storage->svp_release unless $error;
        };
    }

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stacks => [$stack]);
    $stack->commit(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pull {
    my ($self, $target, $stack) = @_;

    if (itis($target, 'Pinto::PackageSpec') && $self->_is_core_package($target, $stack)) {
        $self->debug("$target is part of the perl core.  Skipping it");
        return;
    }

    $self->notice("Pulling $target");

    my $dist = $self->repo->find_or_pull(target => $target, stack => $stack);
    # TDOO: what if $dist comes back undef?
    $stack->register(distribution => $dist, pin => $self->pin);

    if ($dist and not $self->norecurse) {
        $self->repo->pull_prerequisites(dist => $dist, stack => $stack);
    }

    return;
}

#------------------------------------------------------------------------------

sub _is_core_package {
    my ($self, $pspec, $stack) = @_;

    my $wanted_package = $pspec->name;
    my $wanted_version = $pspec->version;

    return if not exists $Module::CoreList::version{ $] }->{$wanted_package};

    my $core_version = $Module::CoreList::version{ $] }->{$wanted_package};
    return $core_version >= $wanted_version;
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $targets  = join ', ', $self->targets;
    my $pinned   = $self->pin       ? ' and pinned'            : '';
    my $prereqs  = $self->norecurse ? ' without prerequisites' : '';

    return "Pulled${pinned} ${targets}$prereqs.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
