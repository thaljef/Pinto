# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

use Pinto::Types qw(Author Files StackName StackDefault);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig Pinto::Role::Committable );

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => Author,
    default    => sub { uc ($_[0]->pausecfg->{user} || $_[0]->config->username) },
    coerce     => 1,
    lazy       => 1,
);


has archives  => (
    isa       => Files,
    traits    => [ qw(Array) ],
    handles   => {archives => 'elements'},
    required  => 1,
    coerce    => 1,
);


has stack => (
    is       => 'ro',
    isa      => StackName | StackDefault,
    default  => undef,
    coerce   => 1,
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

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my @missing = grep { not -e $_ } $self->archives;
    $self->error("Archive $_ does not exist") for @missing;

    my @unreadable = grep { -e $_ and not -r $_ } $self->archives;
    $self->error("Archive $_ is not readable") for @unreadable;

    throw "Some archives are missing or unreadable"
        if @missing or @unreadable;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->open_stack(name => $self->stack);
    $self->_add($_, $stack) for $self->archives;
    $self->result->changed if $stack->refresh->has_changed;

    if ($stack->has_changed and not $self->dryrun) {
        my $message = $self->edit_message(stacks => [$stack]);
        $stack->close(message => $message);
        $self->repos->write_index(stack => $stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _add {
    my ($self, $archive, $stack) = @_;

    $self->notice("Adding distribution archive $archive");

    my $dist  = $self->repos->add( archive   => $archive,
                                   author    => $self->author );

    $dist->register( stack => $stack, pin => $self->pin );

    $self->repos->pull_prerequisites( dist  => $dist,
                                      stack => $stack ) unless $self->norecurse;

    return;
}

#------------------------------------------------------------------------------

sub message_primer {
    my ($self) = @_;

    my $archives  = join ', ', map {$_->basename} $self->archives;
    my $pinned    = $self->pin       ? ' and pinned'            : '';
    my $prereqs   = $self->norecurse ? ' without prerequisites' : '';

    return "Added${pinned} ${archives}$prereqs.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
