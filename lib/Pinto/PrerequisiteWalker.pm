# ABSTRACT: Iterates through distribution prerequisites

package Pinto::PrerequisiteWalker;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(CodeRef ArrayRef HashRef Bool);
use MooseX::MarkAsMethods (autoclean => 1);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has start => (
	is       => 'ro',
	isa      => 'Pinto::Schema::Result::Distribution',
	required => 1,
);


has callback => (
	is       => 'ro',
	isa      => CodeRef,
	required => 1,
);


has filter => (
  is        => 'ro',
  isa       => CodeRef,
  predicate => 'has_filter',
);


has queue => (
  isa       => ArrayRef['Pinto::PackageSpec'],
  traits    => [ qw(Array) ],
  handles   => {enqueue => 'push', dequeue => 'shift'},
  default   => sub { return [ $_[0]->apply_filter($_[0]->start->prerequisite_specs) ] },
  init_arg  => undef,
  lazy      => 1,
);


has seen => (
  is       => 'ro',
  isa      => HashRef,
  default  => sub { return { $_[0]->start->path => 1 } },
  init_arg => undef,
  lazy     => 1,
);

#-----------------------------------------------------------------------------

sub next {
  my ($self) = @_;

  my $prereq = $self->dequeue or return;
  my $dist   = $self->callback->($prereq);

  if (defined $dist) {
    my $path    = $dist->path;
    my @prereqs = $self->apply_filter($dist->prerequisite_specs);
    $self->enqueue(@prereqs) unless $self->seen->{$path};
    $self->seen->{$path} = 1;
  }

  return $prereq;
}

#------------------------------------------------------------------------------

sub apply_filter {
  my ($self, @prereqs) = @_;

  return @prereqs if not $self->has_filter;

  return grep { ! $self->filter->($_) } @prereqs;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
