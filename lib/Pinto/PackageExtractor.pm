# ABSTRACT: Extract packages provided/required by a distribution archive

package Pinto::PackageExtractor;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(HashRef Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Dist::Metadata;
use Path::Class qw(dir);
use Archive::Extract;

use Pinto::Types qw(File Dir);
use Pinto::Util qw(debug throw whine);
use Pinto::ArchiveUnpacker;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);

has unpacker => (
    is       => 'ro',
    isa      => 'Pinto::ArchiveUnpacker',
    default  => sub { Pinto::ArchiveUnpacker->new( archive => $_[0]->archive ) },
    init_arg => undef,
    lazy     => 1,
);

has work_dir => (
    is       => 'ro',
    isa      => Dir,
    default  => sub { $_[0]->unpacker->unpack },
    init_arg => undef,
    lazy     => 1,
);

has dm => (
    is       => 'ro',
    isa      => 'Dist::Metadata',
    default  => sub { Dist::Metadata->new( dir => $_[0]->work_dir, include_inner_packages => 1 ) },
    init_arg => undef,
    lazy     => 1,
);

#-----------------------------------------------------------------------------

sub provides {
    my ($self) = @_;

    my $archive = $self->archive;
    debug "Extracting packages provided by archive $archive";

    my $mod_info = try {

        # Some modules get their VERSION by loading some other
        # module from lib/.  So make sure that lib/ is in @INC
        my $lib_dir = $self->work_dir->subdir('lib');
        local @INC = ( $lib_dir->stringify, @INC );

        # TODO: Run this under Safe to protect ourselves
        # from evil.  See ANDK/pause/pmfile.pm for example
        $self->dm->module_info;    # returned from try{}
    }
    catch {
        throw "Unable to extract packages from $archive: $_";
    };

    my @provides;
    for my $pkg_name ( sort keys %{$mod_info} ) {

        my $info    = $mod_info->{$pkg_name};
        my $pkg_ver = version->parse( $info->{version} );
        debug "Archive $archive provides: $pkg_name-$pkg_ver";

        push @provides, { name => $pkg_name, version => $pkg_ver };
    }

    @provides = $self->__apply_workarounds if @provides == 0;

    whine sprintf "%s contains no packages and will not be indexed",
        $archive->basename if not @provides;

    return @provides;
}

#-----------------------------------------------------------------------------

sub requires {
    my ($self) = @_;

    my $archive = $self->archive;
    debug "Extracting packages required by archive $archive";

    my $prereqs_meta = try { $self->dm->meta->prereqs } 
                     catch { throw "Unable to extract prereqs from $archive: $_" };

    my @prereqs;
    for my $phase ( keys %{$prereqs_meta} ) {

        my $prereqs_for_phase = $prereqs_meta->{$phase}        || {};
        my $required_prereqs  = $prereqs_for_phase->{requires} || {};

        for my $pkg_name ( sort keys %{$required_prereqs} ) {

            my $pkg_ver = version->parse( $required_prereqs->{$pkg_name} );
            debug "Archive $archive requires ($phase): $pkg_name-$pkg_ver";

            my $struct = { phase => $phase, name => $pkg_name, version => $pkg_ver };
            push @prereqs, $struct;
        }
    }

    my $base = $archive->basename;

    whine "$base appears to be a bundle.  Prereqs for bundles cannot be determined automatically"
        if $base =~ m/^ Bundle- /x;

#    whine "$base uses dynamic configuration so prereqs may be incomplete"
#        if $self->dm->meta->dynamic_config;

    return @prereqs;
}

#-----------------------------------------------------------------------------

sub metadata {
    my ($self) = @_;

    my $archive = $self->archive;
    debug "Extracting metadata from archive $archive";

    my $metadata = try { $self->dm->meta } catch { throw "Unable to extract metadata from $archive: $_" };

    return $metadata;
}

#-----------------------------------------------------------------------------
# HACK: The common-sense and FCGI distributions generate the .pm file at build
# time.  It relies on an unusual feature of PAUSE that scans the __DATA__
# section of .PM files for potential packages.  Module::Metdata doesn't have
# that feature, so to us, it appears that these distributions contain no packages.
# I've asked the authors to use the "provides" field of the META file so
# that other tools can discover the packages in the distribution, but then have
# not done so.  So we work around it by just assuming the distribution contains a
# package named "common::sense" or "FCGI".

sub __apply_workarounds {
    my ($self) = @_;

    return $self->__common_sense_workaround
        if $self->archive->basename =~ m/^ common-sense /x;

    return $self->__fcgi_workaround
        if $self->archive->basename =~ m/^ FCGI-\d /x;

    return;
}

#-----------------------------------------------------------------------------
# TODO: Generalize both of these workaround methods into a single method that
# just guesses the package name and version based on the distribution name.

sub __common_sense_workaround {
    my ($self) = @_;

    my ($version) = ( $self->archive->basename =~ m/common-sense- ([\d_.]+) \.tar\.gz/x );

    return {
        name    => 'common::sense',
        version => version->parse($version)
    };
}

#-----------------------------------------------------------------------------
# TODO: Generalize both of these workaround methods into a single method that
# just guesses the package name and version based on the distribution name.

sub __fcgi_workaround {
    my ($self) = @_;

    my ($version) = ( $self->archive->basename =~ m/FCGI- ([\d_.]+) \.tar\.gz/x );

    return {
        name    => 'FCGI',
        version => version->parse($version)
    };
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__
