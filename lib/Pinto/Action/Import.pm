package Pinto::Action::Import;

# ABSTRACT: Import a distribution (and dependencies) into the local repository

use version;

use Moose;
use MooseX::Types::Moose qw(Str Bool);

use Try::Tiny;

use Pinto::PackageExtractor;
use Pinto::Exceptions qw(throw_error);
use Pinto::Types qw(Vers);
use Pinto::Util;

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


has package_extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy_build => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::FileFetcher );

#------------------------------------------------------------------------------
# Builders

sub _build_package_extractor {
    my ($self) = @_;

    return Pinto::PackageExtractor->new( config => $self->config(),
                                         logger => $self->logger() );
}

#------------------------------------------------------------------------------

# TODO: Allow the import target to be specified as a package/version,
# dist path, or a particular URL.  Then do the right thing for each.

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $wanted = { name    => $self->package_name(),
                   version => $self->minimum_version() };

    my $dist = $self->_find_or_import( $wanted );
    return 0 if not $dist;

    my $archive = $dist->archive( $self->repos->root_dir() );
    $self->_descend_into_prerequisites($archive) unless $self->norecurse();

    return 1;
}

#------------------------------------------------------------------------------

sub _find_or_import {
    my ($self, $pkg_spec) = @_;

    my ($pkg_name, $pkg_ver) = ($pkg_spec->{name}, $pkg_spec->{version});
    my $pkg_vname = "$pkg_name-$pkg_ver";

    my $where   = {name => $pkg_name, is_latest => 1};
    my $got_pkg = $self->repos->select_packages( $where )->single();

    if ($got_pkg and $got_pkg->version() >= $pkg_ver) {
        $self->debug("Already have package $pkg_vname or newer as $got_pkg");
        return $got_pkg->distribution();
    }

    if (my $url = $self->repos->cache->locate( $pkg_name => $pkg_ver ) ) {
        $self->debug("Found package $pkg_vname or newer in $url");

        if ( Pinto::Util::isa_perl($url) ) {
            $self->info("Distribution $url is a perl.  Skipping it.");
            return;
        }

        return $self->_import_distribution($url);
    }

    throw_error "Cannot find $pkg_vname anywhere";

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
             my $pretty = "$prereq->{name}-$prereq->{version}";
             $self->whine("Skipping prerequisite $pretty. $_");
             # Mark the prereq as done so we don't try to import it again
             $done{ $prereq->{name} } = $prereq;
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

            # Add this prereq to the queue only if greater than the ones we already got
            my $name = $new_prereq->{name};
            next NEW_PREREQ if exists $done{$name}
                               && $new_prereq->{version} <= $done{$name};

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

    my @prereqs = try   { $self->package_extractor->requires( archive => $archive ) }
                  catch { $self->whine("Unable to extract prerequisites from $archive: $_"); () };

    return @prereqs;
}

#------------------------------------------------------------------------------

sub _import_distribution {
    my ($self, $url) = @_;

    my ($source, $path, $author, $destination) =
        Pinto::Util::parse_dist_url( $url, $self->config->root_dir() );

    my $where    = {path => $path};
    my $existing = $self->repos->select_distributions( $where )->single();
    throw_error "Distribution $path already exists" if $existing;

    $self->fetch(from => $url, to => $destination);

    my @pkg_specs = $self->package_extractor->provides(archive => $destination);
    $self->info(sprintf "Importing distribution $url providing %d packages", scalar @pkg_specs);

    my $struct = { path     => $path,
                   source   => $source,
                   mtime    => Pinto::Util::mtime($destination),
                   packages => \@pkg_specs };

    my $dist = $self->repos->add_distribution($struct);

    return $dist;
}
#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
