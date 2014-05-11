# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Target;
use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa => ArrayRef [Str],
    traits   => ['Array'],
    handles  => { targets => 'elements' },
    writer   => '_targets',
    default  => sub { [] },
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

has all => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller Pinto::Role::Installer);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    throw "Cannot specify targets when the 'all' option is used"
        if $self->all and $self->targets;

    throw "Must specify targets or use the 'all' option"
        unless $self->all or $self->targets;

    throw "Cannot use 'do_pull' and 'all' options together"
        if $self->all and $self->do_pull;

    if ($self->all) {
        my $stack = $self->repo->get_stack($self->stack);
        my @packages = map {$_->package_name} $stack->head->registrations;
        $self->_targets(\@packages);
    }

    return $self;
}

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
