# ABSTRACT: Extract packages provided/required by a distribution archive

package Pinto::PackageExtractor;

use Moose;
use MooseX::Types::Moose qw(HashRef Bool);

use Try::Tiny;
use Dist::Metadata;
use Module::CoreList;

use Pinto::Exception qw(throw);
use Pinto::Types qw(File Vers);

use version;
use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( Pinto::Role::Loggable );

#-----------------------------------------------------------------------------

has archive => (
    is       => 'ro',
    isa      => File,
    required => 1,
    coerce   => 1,
);


has target_perl_version => (
    is         => 'ro',
    isa        => Vers,
    default    => sub { version->parse( $] ) },
    coerce     => 1,
    lazy       => 1,
);


has dm => (
    is       => 'ro',
    isa      => 'Dist::Metadata',
    default  => sub { Dist::Metadata->new(file => $_[0]->archive->stringify) },
    init_arg => undef,
    lazy     => 1,
);


has prereq_filter => (
    is         => 'ro',
    isa        => HashRef,
    builder    => '_build_prereq_filter',
    lazy       => 1,
);

#-----------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    # version.pm doesn't always strip trailing zeros
    my $tpv = $self->target_perl_version->numify + 0;

    throw "The target_perl_version ($tpv) cannot be greater than this perl ($])"
        if $tpv > $];

    throw "Unknown version of perl: $tpv"
        if not exists $Module::CoreList::version{$tpv};  ## no critic (PackageVar)

    return $self;
}

#-----------------------------------------------------------------------------

sub _build_prereq_filter {
    my ($self) = @_;

    # version.pm doesn't always strip trailing zeros
    my $tpv           = $self->target_perl_version->numify + 0;
    my %core_packages = %{ $Module::CoreList::version{$tpv} };  ## no critic (PackageVar)

    $_ = version->parse($_) for values %core_packages;

    return \%core_packages;
}


#-----------------------------------------------------------------------------

sub provides {
    my ($self) = @_;

    my $archive = $self->archive;
    $self->info("Extracting packages provided by archive $archive");

    my $provides =   try { $self->dm->package_versions }
                   catch { throw "Unable to extract packages from $archive: $_"    };

    my @provides;
    for my $pkg_name ( sort keys %{ $provides } ) {
        my $pkg_ver = version->parse( $provides->{$pkg_name} );
        $self->debug("Archive $archive provides: $pkg_name-$pkg_ver");
        push @provides, {name => $pkg_name, version => $pkg_ver};
    }

    @provides = $self->__common_sense_workaround($archive->basename)
      if @provides == 0 and $archive->basename =~ m/^ common-sense /x;

    $self->warning("$archive provides no packages") if not @provides;

    return @provides;
}

#-----------------------------------------------------------------------------

sub requires {
    my ($self) = @_;

    my $archive = $self->archive;
    $self->info("Extracting packages required by archive $archive");

    my $prereqs_meta =   try { $self->dm->meta->prereqs }
                       catch { throw "Unable to extract prereqs from $archive: $_" };

    my %prereqs;
    for my $phase ( qw( configure build test runtime ) ) {
        my $p = $prereqs_meta->{$phase} || {};
        %prereqs = ( %prereqs, %{ $p->{requires} || {} } );
    }


    my @prereqs;
    for my $pkg_name (sort keys %prereqs) {
        my $pkg_ver = version->parse( $prereqs{$pkg_name} );

        next if $pkg_name eq 'perl';

        next if exists $self->prereq_filter->{$pkg_name}
          and $self->prereq_filter->{$pkg_name} >= $pkg_ver;

        $self->debug("Archive $archive requires: $pkg_name-$pkg_ver");
        push @prereqs, {name => $pkg_name, version => $pkg_ver};
    }

    return @prereqs;
}

#-----------------------------------------------------------------------------
# HACK: The common-sense distribution generates the .pm file at build time.
# It relies on an unusual feature of PAUSE that scans the __DATA__ section
# of .PM files for potential packages.  Module::Metdata doesn't have that
# feature, so to us, it appears that common-sense contains no packages.
# I've asked the author to use the "provides" field of the META file so
# that other tools can discover the packages in his distribution, but
# he has refused to do so.  So we work around it by just assuming the
# distribution contains a package named "common::sense".

sub __common_sense_workaround {
    my ($self, $cs_archive) = @_;

    my ($version) = ($cs_archive =~ m/common-sense- ([\d_.]+) \.tar\.gz/x);

    return { name => 'common::sense',
             version => version->parse($version) };
}

#-----------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__
