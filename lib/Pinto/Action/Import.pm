package Pinto::Action::Import;

# ABSTRACT: Import a distribution (and dependencies) into the local repository

use version;

use Moose;
use MooseX::Types::Moose qw(Str Bool);

use Try::Tiny;

use Pinto::PackageSpec;
use Pinto::Extractor::Requires;

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
    isa     => 'version',
    default => sub { version->parse(0) },
);


has norecurse => (
   is      => 'ro',
   isa     => Bool,
   default => 0,
);


has get_latest => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

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

    if ($got_pkg and $pkg_spec < $got_pkg->version()) {
        $self->debug("Already have $pkg_spec or newer as $got_pkg");
        return $got_pkg->distribution();
    }

    if (my $url = $self->repos->locate_remotely( $pkg_spec ) ) {
        $self->debug("Found $pkg_spec in $url");
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

    while (my $prereq = shift @prereq_queue) {

        my $required_archive;

        try {
              my $required_dist = $self->_find_or_import( $prereq );
              $required_archive = $required_dist->archive( $self->config->root_dir() );
        }
        catch {
             $self->whine("Skipping prerequisite $prereq.  Import failed: $_");
             $done{ $prereq->name() } = $prereq;
             next;
        };


        if ( $visited{$required_archive} ) {
            # We don't need to extract prereqs from the same dist more than once
            $self->debug("Already visited archive $required_archive");
            next;
        }

        for my $new_prereq ( $self->_extract_prerequisites($required_archive) ) {
            # Add a prereq to the queue only if greater than the ones we already got
            my $name = $new_prereq->name();
            next if exists $done{$name} && ( $new_prereq < $done{$name} );

            $done{$name} = $new_prereq;
            push @prereq_queue, $new_prereq;
        }

        $visited{$required_archive}++;
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _extract_prerequisites {
    my ($self, $archive) = @_;

    my $req = Pinto::Extractor::Requires->new( config => $self->config(),
                                               logger => $self->logger() );

    # If extraction fails, then just warn and return an empty list.  The
    # caller should just go on to the next archive.  The user will have
    # to figure out the prerequisites by other means.

    my @prereqs;
    try   { @prereqs = $req->extract( archive => $archive ) }
    catch { $self->whine("Unable to extract prerequisites from $archive: $_") };

    return @prereqs;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
