package Pinto::Action::Import;

# ABSTRACT: Import a distribution (and dependencies) into the local repository

use version;

use Moose;
use MooseX::Types::Moose qw(Str Bool);

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

    # if: we have requested dist/package
    #     return if $self->recurse();
    #     goto foreach

    # else:
    #       get requested dist
    #       add requested dist to repository
    #       return if not $self->recurse();

    # foreach: dist requirement
    #      if: we have required package
    #          next requirement
    #      else:
    #          get dist
    #          add dist to repository
    #          recurse

    $DB::single = 1;
    my $wanted = { name => $self->package_name(), version => $self->minimum_version() };
    my $dist = $self->_find_or_import( $wanted );
    return 0 if not $dist;

    my $archive = $dist->archive( $self->repos->root_dir() );
    $self->_descend_into_prerequisites($archive) unless $self->norecurse();

    return 1;
}

#------------------------------------------------------------------------------

sub _find_or_import {
    my ($self, $wanted_package_spec) = @_;

    my ($pkg_name, $pkg_ver) = @$wanted_package_spec{ qw(name version) };

    my $pretty_pkg = "$pkg_name-$pkg_ver";
    my $got_pkg = $self->repos->db->get_latest_package_with_name( $pkg_name );

    if ($got_pkg and $got_pkg->version_numeric() >= $pkg_ver->numify() ) {
        $self->debug("Already have $pretty_pkg or newer as $got_pkg");
        return $got_pkg->distribution();
    }

    if (my $url = $self->repos->locate_remotely( $pkg_name => $pkg_ver ) ) {
        $self->debug("Found $pretty_pkg in $url");
        return $self->repos->import_distribution( url => $url );
        # TODO: catch exception
    }

    $self->whine("Cannot find $pretty_pkg anywhere");

    return;
}

#------------------------------------------------------------------------------

sub _descend_into_prerequisites {
    my ($self, $archive) = @_;

          $DB::single = 1;
    my @prerequisites = $self->_extract_prerequisites($archive);

    while (my $prereq = pop @prerequisites) {

        # TODO: log activity
        # TODO: catch exceptions

        my $required_dist    = $self->_find_or_import( $prereq ) or next;
        my $required_archive = $required_dist->archive( $self->config->root_dir() );
        push @prerequisites, $self->_extract_prerequisites( $required_archive );
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _extract_prerequisites {
    my ($self, $archive) = @_;

    my $req = Pinto::Extractor::Requires->new( config => $self->config(),
                                               logger => $self->logger() );

    my @prereqs = $req->extract( archive => $archive );

    return @prereqs;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
