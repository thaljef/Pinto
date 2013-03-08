# ABSTRACT: Iterates through distribution prerequisites

package Pinto::PrerequisiteWalker;

use Moose;
use MooseX::Types::Moose qw(Bool CodeRef HashRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);
use Pinto::PrerequisiteFilter::None;

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


has skip_seen => (
	is      => 'ro',
	isa     => Bool,
	default => 1,
);


has filter => (
    is         => 'ro',
    isa        => 'Pinto::PrerequisiteFilter',
    default    => sub { Pinto::PrerequisiteFilter::None->new },
    lazy       => 1,
);

#-----------------------------------------------------------------------------

sub walk {
  my ($self) = @_;

	my @queue = $self->start->prerequisite_specs;
    my %visited_dists = ($self->start->path => 1);
    my %latest_pkgs;

  PREREQ:
    while (my $prereq = shift @queue) {

        next PREREQ if $self->filter->should_filter($prereq);

    	my $dist = $self->callback->($self, $prereq);
    	next PREREQ if !$dist || $visited_dists{$dist->path};

      NEW_PREREQ:
        for my $new_prereq ( $dist->prerequisite_specs ) {

        	my $name = $new_prereq->name;

            # Add this prereq to the queue only if greater than the ones we already got
            if (! exists $latest_pkgs{$name} or $new_prereq->{version} >= $latest_pkgs{$name} ) {

            	# Take any prior versions of this prereq out of the queue
            	@queue = grep { $_->{name} ne $name } @queue if $self->skip_seen;

            	# Note that this is the latest version of this prereq we've seen so far
            	$latest_pkgs{$name} = $new_prereq->{version};

            	# Push the prereq onto the queue
            	push @queue, $new_prereq;
            }

        }

        $visited_dists{$dist->path} = 1;
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
