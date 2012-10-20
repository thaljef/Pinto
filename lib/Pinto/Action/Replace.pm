# ABSTRACT: Replace a distribution archive within the repository

package Pinto::Action::Replace;

use Moose;
use MooseX::Types::Moose qw(Bool);

use Pinto::Types qw(Author DistSpec StackName StackDefault File);
use Pinto::Exception qw(throw);

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
    default    => sub { uc($_[0]->pausecfg->{user} || '') || $_[0]->config->username },
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

    throw "Archive $archive does not exist"  if not -e $archive;
    throw "Archive $archive is not readable" if not -r $archive;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $target = $self->target;
    my $old_dist  = $self->repos->get_distribution( spec => $target );

    throw "Distribution $target is not in the repository" if not $old_dist;

    my $new_dist = $self->repos->add( archive => $self->archive,
                                      author  => $self->author );

    my @registered_stacks = $old_dist->registered_stacks;
    my @changed_stacks = grep {$self->_replace( $_, $old_dist, $new_dist )} @registered_stacks;
    return $self->result if not @changed_stacks;

    my $message = $self->edit_message(stacks => \@changed_stacks);

    for my $stack (@changed_stacks) {
        $stack->close(message => $message);
        $self->repos->write_index(stack => $stack);
    }

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _replace {
    my ($self, $stack, $old_dist, $new_dist) = @_;

    $self->repos->open_stack(stack => $stack);

    for my $package ($old_dist->packages) {
        my $reg = $package->registration(stack => $stack) or next;
        $reg->delete;
    }

    $new_dist->register( stack => $stack, pin => $self->pin );

    $self->repos->pull_prerequisites( dist  => $new_dist,
                                      stack => $stack ) unless $self->norecurse;

    return $stack if $stack->refresh->has_changed;
}

#------------------------------------------------------------------------------

sub message_primer {
    my ($self) = @_;

    my $target  = $self->target;
    my $archive = $self->archive->basename;

    return "Replaced $target with $archive.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
