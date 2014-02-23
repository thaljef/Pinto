# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;

use Pinto::Util qw(throw);
use Pinto::Types qw(File TargetList);

use Module::CPANfile;
use Pinto::Target::Package;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa     => TargetList,
    traits  => [qw(Array)],
    handles => {
        add_targets => 'push',
        targets     => 'elements'
    },
    coerce  => 1,
    default => sub { [] },
);

has cpanfile => (
    is     => 'ro',
    isa    => File,
    coerce => 1,
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

    if ( $self->cpanfile ) {
        $self->_add_cpanfile_targets();
    }

    $self->targets || die "Attribute \(targets\) is required";

    $self->stack->assert_not_locked;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ( @successful, @failed );
    for my $target ( $self->targets ) {

        try {
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

sub _add_cpanfile_targets {
    my ($self) = @_;

    my $cpanfile = $self->cpanfile()->absolute;

    # https://metacpan.org/pod/CPAN::Meta::Spec#PREREQUISITES
    my @phases = qw(configure build test runtime develop);
    my @types  = qw(requires recommends suggests);           # exclude "conflicts"

    my $args;
    try {
        my $file = Module::CPANfile->load($cpanfile);
        my $prereqs = $file->prereqs->merged_requirements( \@phases, \@types );
        $args = $prereqs->as_string_hash;
    }
    catch {
        die "Unable to load requirements from $cpanfile: $_";
    };

    for my $name ( keys %{$args} ) {
        my $ptp = Pinto::Target::Package->new(
            {   name    => $name,
                version => $args->{$name}
            }
        );
        $self->add_targets($ptp);
    }

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
