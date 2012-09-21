# ABSTRACT: Replace a distribution archive within the repository

package Pinto::Action::Replace;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Types qw(Author DistSpec StackName StackDefault File);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig Pinto::Role::Committable);

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => Author,
    default    => sub { uc ($_[0]->pausecfg->{user} || $_[0]->config->username) },
    coerce     => 1,
    lazy       => 1,
);


has target  => (
    is        => 'ro',
    isa       => DistSpec,
    required  => 1,
    coerce    => 1,
);


has archive  => (
    is        => 'ro',
    isa       => File,
    required  => 1,
    coerce    => 1,
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

    my $archive = $self->archive;

    $self->fatal("Archive $archive does not exist")
      if not -e $archive;

    $self->fatal("Archive $archive is not readable")
      if not -r $archive;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $target = $self->target;
    my $old_dist  = $self->repos->get_distribution( spec => $target );

    $self->fatal("Distribution $target is not in the repository")
      if not $old_dist;

    my $new_dist = $self->repos->add( archive => $self->archive,
                                      author  => $self->author );

    my @registered_stacks = $old_dist->registered_stacks;
    my @changed_stacks = grep {$self->_replace( $_, $new_dist )} @registered_stacks;
    return $self->result if not @changed_stacks;

    my $primer = join "\n\n", map {$_->head_revision->change_details} @changed_stacks;
    my $message = $self->edit_message(primer => $primer);

    for my $stack (@changed_stacks) {
        $stack->close(message => $message);
        $self->repos->write_index(stack => $stack);
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _replace {
    my ($self, $stack, $dist) = @_;

    $self->repos->open_stack(stack => $stack);

    $dist->register( stack => $stack );
    $dist->pin( stack => $stack ) if $self->pin;

    $self->repos->pull_prerequisites( dist  => $dist,
                                      stack => $stack ) unless $self->norecurse;

    return $stack if $stack->refresh->has_changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
