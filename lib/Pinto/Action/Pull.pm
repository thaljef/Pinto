# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;

use Pinto::Util qw(throw);
use Pinto::Types qw(SpecList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
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
    for my $target ( $self->targets ) {


        try {
            $DB::single = 1;
            $self->repo->svp_begin;
            $self->notice( "Pulling target $target to stack " . $self->stack );
            my $dist = $self->pull( target => $target );
            push @successful, $dist ? $dist : ();
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

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
