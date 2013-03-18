# ABSTRACT: Base class for prereq filters

package Pinto::PrerequisiteFilter;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub should_filter {
    my ($self, $prereq) = @_;
    throw 'Abstract method';
}

#------------------------------------------------------------------------------

sub apply {
	my ($self, @prereqs) = @_;
	return grep { ! $self->should_filter($_) } @prereqs;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
