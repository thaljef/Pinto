# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Target;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa => ArrayRef [Str],
    traits   => ['Array'],
    handles  => { targets => 'elements' },
    required => 1,
);

has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has mirror_uri => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_mirror_uri',
    lazy    => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller Pinto::Role::Installer);

#------------------------------------------------------------------------------

sub _build_mirror_uri {
    my ($self) = @_;

    my $stack      = $self->stack;
    my $stack_dir  = defined $stack ? "/stacks/$stack" : '';
    my $mirror_uri = 'file://' . $self->repo->root->absolute . $stack_dir;

    return $mirror_uri;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @dists;
    if ( $self->do_pull ) {

        for my $target ( $self->targets ) {
            next if -d $target or -f $target;

            require Pinto::Target;
            $target = Pinto::Target->new($target);

            my $dist = $self->pull( target => $target );
            push @dists, $dist ? $dist : ();
        }
    }

    return @dists;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
