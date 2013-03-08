# ABSTRACT: Iterates through distribution prerequisites

package Pinto::PrerequisiteWalker;

use Moose;
use MooseX::Types::Moose qw(Bool CodeRef HashRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);
use Pinto::Exception qw(throw);

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
    isa        => HashRef,
    default    => sub { {} },
    lazy       => 1,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    if ( itis($args->{filter}, 'version') ) {

        # version.pm doesn't always strip trailing zeros
        my $tpv = $args->{filter}->numify + 0;

        throw "The target_perl_version ($tpv) cannot be greater than this perl ($])"
            if $tpv > $];

        throw "Unknown version of perl: $tpv"
            if not exists $Module::CoreList::version{$tpv};  ## no critic (PackageVar)

        my %core_packages = %{ $Module::CoreList::version{$tpv} };  ## no critic (PackageVar)
        $_ = version->parse($_) for values %core_packages;

        $args->{filter} = \%core_packages;
    }

    return $args;
};

#------------------------------------------------------------------------------

sub walk {
  my ($self) = @_;

	my @queue = $self->start->prerequisite_specs;
    my %visited_dists = ($self->start->path => 1);
    my %latest_pkgs;

  PREREQ:
    while (my $prereq = shift @queue) {

        next PREREQ if $self->should_filter($prereq);
        next PREREQ if $prereq->name eq 'perl';

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

sub should_filter {
    my ($self, $prereq) = @_;

    return defined $self->filter->{$prereq->name}
           && $self->filter->{$prereq->name} >= $prereq->version;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
