package Pinto::Role::PackageImporter;

# ABSTRACT: Something that imports packages from another repository

use Moose::Role;

use Pinto::Util;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Loggable
         Pinto::Role::FileFetcher );

#------------------------------------------------------------------------------
# Required interface

requires qw( repos );

#------------------------------------------------------------------------------

sub find_or_pull {
    my ($self, $target) = @_;

    if ( $target->isa('Pinto::PackageSpec') ){
        return $self->_pull_by_package_spec($target);
    }
    elsif ($target->isa('Pinto::DistributionSpec') ){
        return $self->_pull_by_distribution_spec($target);
    }
    else {
        my $type = ref $target;
        $self->fatal("Don't know how to pull a $type");
    }

}

#------------------------------------------------------------------------------

sub _pull_by_package_spec {
    my ($self, $pspec) = @_;

    $self->info("Looking for package $pspec");

    my ($pkg_name, $pkg_ver) = ($pspec->name, $pspec->version);
    my $latest = $self->repos->get_package(name => $pkg_name);

    if ($latest && $latest->version >= $pkg_ver) {
        my $dist = $latest->distribution;
        $self->debug("Already have package $pspec or newer as $latest");
        $self->repos->register(distribution => $dist, stack => $self->stack);
        return ($dist, 0);
    }

    my $dist_url = $self->repos->locate( package => $pspec->name,
                                         version => $pspec->version,
                                         latest  => 1 );

    $self->fatal("Cannot find prerequisite $pspec anywhere")
      if not $dist_url;

    $self->debug("Found package $pspec or newer in $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it.");
        return (undef, 0);
    }

    $self->notice("Pulling distribution $dist_url");
    my $dist = $self->repos->pull(url => $dist_url);

    $self->repos->register( distribution  => $dist,
                            stack         => $self->stack );

    return ($dist, 1);
}

#------------------------------------------------------------------------------

sub _pull_by_distribution_spec {
    my ($self, $dspec) = @_;

    $self->info("Looking for distribution $dspec");

    my $path     = $dspec->path;
    my $got_dist = $self->repos->get_distribution(path => $path);

    if ($got_dist) {
        $self->info("Already have distribution $dspec");
        $self->repos->register(distribution => $got_dist, stack => $self->stack);
        return ($got_dist, 0);
    }

    my $dist_url = $self->repos->locate(distribution => $dspec->path)
      or $self->fatal("Cannot find prerequisite $dspec anywhere");

    $self->debug("Found package $dspec at $dist_url");

    if ( Pinto::Util::isa_perl($dist_url) ) {
        $self->debug("Distribution $dist_url is a perl. Skipping it.");
        return (undef , 0);
    }

    $self->notice("Pulling distribution $dist_url");
    my $dist = $self->repos->pull(url => $dist_url);

    $self->repos->register( distribution  => $dist,
                            stack         => $self->stack );

    return ($dist, 1);
}

#------------------------------------------------------------------------------

sub pull_prerequisites {
    my ($self, $dist) = @_;

    my @prereq_queue = $dist->prerequisite_specs;
    my %visited = ($dist->path => 1);
    my @pulled;
    my %seen;

  PREREQ:
    while (my $prereq = shift @prereq_queue) {

        my ($required_dist, $did_pull) = $self->find_or_pull( $prereq );
        next PREREQ if not ($required_dist and $did_pull);
        push @pulled, $required_dist if $did_pull;

        if ( $visited{$required_dist->path} ) {
            # We don't need to recurse into prereqs more than once
            $self->debug("Already visited archive $required_dist");
            next PREREQ;
        }

      NEW_PREREQ:
        for my $new_prereq ( $required_dist->prerequisite_specs ) {

            # This is all pretty hacky.  It might be better to represent the queue
            # as a hash table instead of a list, since we really need to keep track
            # of things by name.

            # Add this prereq to the queue only if greater than the ones we already got
            my $name = $new_prereq->{name};

            next NEW_PREREQ if exists $seen{$name}
                               && $new_prereq->{version} <= $seen{$name};

            # Take any prior versions of this prereq out of the queue
            @prereq_queue = grep { $_->{name} ne $name } @prereq_queue;

            # Note that this is the latest version of this prereq we've seen so far
            $seen{$name} = $new_prereq->{version};

            # Push the prereq onto the queue
            push @prereq_queue, $new_prereq;
        }

        $visited{$required_dist->path} = 1;
    }

    return @pulled;
}

#------------------------------------------------------------------------------

1;

__END__
