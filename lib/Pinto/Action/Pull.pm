# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);

use Try::Tiny;
use Module::CoreList;

use Pinto::Util qw(itis);
use Pinto::Types qw(SpecList StackName StackDefault StackObject);

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


has no_recurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has no_fail => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------


sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack)->start_revision;

    my (@successful, @failed);
    for my $target ($self->targets) {

        if (itis($target, 'Pinto::PackageSpec') && $self->_is_core_package($target, $stack)) {
            $self->debug("$target is part of the perl core.  Skipping it");
            next;
        }


        try   {
            $self->repo->db->schema->storage->svp_begin; 
            my $dist = $self->_pull($target, $stack); 
            push @successful, $dist;
        }
        catch {
            die $_ unless $self->no_fail;

            $self->repo->db->schema->storage->svp_rollback;

            $self->error("$_");
            $self->error("$target failed...continuing anyway");
            push @failed, $target;
        }
        finally {
            my ($error) = @_;
            $self->repo->db->schema->storage->svp_release unless $error;
        };
    }

    return $self->result if $self->dry_run or $stack->has_not_changed;

    my $msg_title = $self->generate_message_title(@successful);
    my $msg = $self->compose_message(stack => $stack, title => $msg_title);

    $stack->commit_revision(message => $msg);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _pull {
    my ($self, $target, $stack) = @_;

    $self->notice("Pulling $target");

    my $dist =         $stack->get_distribution(spec => $target)
               || $self->repo->get_distribution(spec => $target)
               || $self->repo->ups_distribution(spec => $target);

    $dist->register(stack => $stack, pin => $self->pin);
    $self->repo->pull_prerequisites(dist => $dist, stack => $stack) if not $self->no_recurse;

    return $dist;
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

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
