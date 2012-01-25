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


has extractor => (
    is         => 'ro',
    isa        => 'Pinto::PackageExtractor',
    lazy_build => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::FileFetcher );

#------------------------------------------------------------------------------
# Builders

sub _build_extractor {
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

    # HACK: We need to return true only if we actually imported
    # something.  If we didn't import anything (i.e. couldn't find
    # anything or we already have everything) then we must return
    # false so that we don't cause an unnecessary VCS commit.
    # Checking the message count is a sleazy way of figuring out how
    # many distributions we actually imported.  TODO: consider using a
    # counter attribute, or refactor _find_or_import so that it can
    # tell you whether or not it actually imported something.

    my @msgs = $self->messages();
    return scalar @msgs;
}

#------------------------------------------------------------------------------

sub _find_or_import {
    my ($self, $pkg_spec) = @_;

    my ($pkg_name, $pkg_ver) = ($pkg_spec->{name}, $pkg_spec->{version});
    my $pkg_vname = "$pkg_name-$pkg_ver";

    $self->note("Looking for package $pkg_vname");

    my $where   = {name => $pkg_name, is_latest => 1};
    my $got_pkg = $self->repos->select_packages( $where )->single();

    if ($got_pkg and $got_pkg->version() >= $pkg_ver) {
        $self->note("Already have package $pkg_vname or newer as $got_pkg");
        return $got_pkg->distribution();
    }

    my $dist_url = $self->repos->cache->locate( package => $pkg_name,
                                                version => $pkg_ver,
                                                latest  => 1 );
    if ($dist_url) {
        $self->debug("Found package $pkg_vname or newer in $dist_url");

        if ( Pinto::Util::isa_perl($dist_url) ) {
            $self->debug("Distribution $dist_url is a perl.  Skipping it.");
            return;
        }

        return $self->_import_distribution($dist_url);
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
             my $prereq_vname = "$prereq->{name}-$prereq->{version}";
             $self->whine("Skipping prerequisite $prereq_vname. $_");
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

            $done{$name} = $new_prereq->{version};
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

    my @prereqs = try   { $self->extractor->requires( archive => $archive ) }
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

    my @pkg_specs = $self->extractor->provides(archive => $destination);
    $self->info(sprintf "Importing distribution $url providing %d packages", scalar @pkg_specs);

    my $struct = { path     => $path,
                   source   => $source,
                   mtime    => Pinto::Util::mtime($destination),
                   packages => \@pkg_specs };

    my $dist = $self->repos->add_distribution($struct);

    $self->add_message( Pinto::Util::imported_dist_message($dist) );

    return $dist;
}
#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
