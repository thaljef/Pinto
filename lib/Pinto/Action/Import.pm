package Pinto::Action::Import;

# ABSTRACT: Import a distribution (and dependencies) into the local repository

use version;

use Moose;

use MooseX::Types::Moose qw(Str Bool);

use Exception::Class::TryCatch;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# ISA

extends 'Pinto::Action';

#------------------------------------------------------------------------------
# Moose Attributes

has package => (
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


has latest => (
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

    my $dist = $self->_find_or_import( $self->package() => $self->minimum_version() );
    return 0 if not $dist;

    my $archive = $dist->archive( $self->config->root_dir() );
    $self->_descend_into_prerequisites($archive) unless $self->norecurse();

    return 1;
}

#------------------------------------------------------------------------------

sub _find_or_import {
    my ($self, $pkg_name, $pkg_ver) = @_;

    my $pretty_pkg = "$pkg_name-$pkg_ver";
    my $pkg = $self->repos->db->get_latest_package_with_name( $pkg_name );

    if ($pkg and $pkg->version_numeric() >= $pkg_ver->numfiy() ) {
        $self->debug("Already have $pretty_pkg or newer as $pkg");
        return $pkg->distribution();
    }

    if (my $url = $self->repos->locate_remotely( $pkg_name => $pkg_ver ) ) {
        $self->debug("Found $pretty_pkg in $url");
        return $self->repos->import_archive($url);
        # TODO: catch exception
    }

    $self->whine("Cannot find $pretty_pkg in anywhere");

    return;
}

#------------------------------------------------------------------------------

sub _descend_into_prerequisites {
    my ($self, $archive) = @_;

    my @prerequisites = $self->exctract_prerequisites($archive);

    while (my $prereq = pop @prerequisites) {

        # TODO: log activity
        # TODO: catch exceptions

        my $required_dist    = $self->_find_or_import( %{ $prereq } ) or next;
        my $required_archive = $required_dist->archive( $self->config->root_dir() );
        push @prerequisites, $self->_extract_prerequisites( $required_archive );
    }

    return 1;
}

#------------------------------------------------------------------------------

sub _extract_prequisites {
    my ($self, $archive) = @_;

    my $req = Dist::Requires->new();

    return $req->requires(dist => $archive);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
