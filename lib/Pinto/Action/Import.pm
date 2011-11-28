package Pinto::Action::Import;

# ABSTRACT: Import a distribution (and dependencies) into the local repository

use version;

use Moose;
use MooseX::Types::Moose qw(Str Bool);

use Try::Tiny;

use Pinto::PackageSpec;
use Pinto::Types qw(Vers);

use version;
use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

has package_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);


has minimum_version => (
    is      => 'ro',
    isa     => Vers,
    default => sub { version->parse(0) },
    coerce  => 1,
);


has norecurse => (
   is      => 'ro',
   isa     => Bool,
   default => 0,
);

#------------------------------------------------------------------------------

# TODO: Allow the import target to be specified as a package/version,
# dist path, or a particular URL.  Then do the right thing for each.

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $wanted = Pinto::PackageSpec->new( name    => $self->package_name(),
                                          version => $self->minimum_version() );

    my $dist = $self->_find_or_import( $wanted );
    return 0 if not $dist;

    my $archive = $dist->archive( $self->repos->root_dir() );
    $self->_descend_into_prerequisites($archive) unless $self->norecurse();

    return 1;
}

#------------------------------------------------------------------------------

sub _find_or_import {
    my ($self, $pkg_spec) = @_;

    my $got_pkg = $self->repos->db->get_latest_package_with_name( $pkg_spec->name() );

    if ($got_pkg and $pkg_spec <= $got_pkg) {
        $self->debug("Already have $pkg_spec or newer as $got_pkg");
        return $got_pkg->distribution();
    }

    if (my $url = $self->repos->locate_remotely( $pkg_spec ) ) {
        $self->debug("Found $pkg_spec in $url");
        return if $self->_isa_perl($url);
        return $self->repos->import_distribution( url => $url );
    }

    $self->whine("Cannot find $pkg_spec anywhere");

    return;
}

#------------------------------------------------------------------------------

sub _descend_into_prerequisites {
    my ($self, $archive) = @_;

    my @prereq_queue = $self->_extract_prerequisites($archive);
    my %visited = ($archive => 1);
    my %done;

  PREREQ:
    while (my $prereq = shift @prereq_queue) {

        my $required_archive = try {
              my $required_dist = $self->_find_or_import( $prereq );
              $required_dist->archive( $self->config->root_dir() );
        }
        catch {
             $self->whine("Skipping prerequisite $prereq.  Import failed: $_");
             # Mark the prereq as done so we don't try to import it again
             $done{ $prereq->name() } = $prereq;
             undef;  # returned by try{}
        };

        next PREREQ if not $required_archive;

        if ( $visited{$required_archive} ) {
            # We don't need to extract prereqs from the same dist more than once
            $self->debug("Already visited archive $required_archive");
            next PREREQ;
        }

      NEW_PREREQ:
        for my $new_prereq ( $self->_extract_prerequisites($required_archive) ) {
            # Add a prereq to the queue only if greater than the ones we already got
            my $name = $new_prereq->name();
            next NEW_PREREQ if exists $done{$name} && ( $new_prereq <= $done{$name} );

            $done{$name} = $new_prereq;
            push @prereq_queue, $new_prereq;
        }

        $visited{$required_archive} = 1;
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _extract_prerequisites {
    my ($self, $archive) = @_;

    # If extraction fails, then just warn and return an empty list.  The
    # caller should just go on to the next archive.  The user will have
    # to figure out the prerequisites by other means.

    my @prereqs = try   { $self->repos->package_extractor->requires( archive => $archive ) }
                  catch { $self->whine("Unable to extract prerequisites from $archive: $_"); () };

    return @prereqs;
}

#------------------------------------------------------------------------------

sub _isa_perl {
    my ($self, $url) = @_;

    # TODO: Should we be checking the core list instead?
    # What should we do if a dist does require a new perl?
    # Should we ever allow perl itself to be imported?

    if ($url =~ m{ / perl-[\d.]+ \.tar \.gz $ }mx) {
        $self->debug("$url is a perl.  Skipping it.");
        return 1;
    }

    return 0;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
