# ABSTRACT: Find a distribution among CPAN-like repositories

package Pinto::TargetLocator;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use URI;

use Pinto::Util qw(throw);
use Pinto::Types qw(Uri Dir);
use Pinto::TargetLocator::Index;
use Pinto::Target;

use version;


#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    weak_ref => 1,
    required => 1,
);

has force => (
   is         => 'ro',
   isa        => 'Bool',
   default    => 0,
);

#------------------------------------------------------------------------------

=method indexes()

Returns a list of L<Package::Locator::Index> objects representing the
indexes of each of the repositories.  The indexes are only populated
on-demand when the C<locate> method is called.  The order of the
indexes is the same as the order of the repositories defined by the
C<repository_urls> attribute.

=cut

has indexes => (
   is         => 'ro',
   isa        => 'ArrayRef[Pinto::TargetLocator::Index]',
   auto_deref => 1,
   lazy_build => 1,
   init_arg   => undef,
);


#------------------------------------------------------------------------------

sub _build_indexes {
    my ($self) = @_;

    my @indexes = map { Pinto::TargetLocator::Index->new(
        force          => $self->force,
        user_agent     => $self->repo->ua,
        cache_dir      => $self->repo->config->cache_dir,
        repository_url => $_ ) } $self->repo->config->sources_list;

    return \@indexes;
}

#------------------------------------------------------------------------------

=method locate( package => 'Foo::Bar' )

=method locate( package => 'Foo::Bar', latest => 1 )

=method locate( package => 'Foo::Bar', version => '1.2')

=method locate( package => 'Foo::Bar', version => '1.2', latest => 1 )

=method locate ( distribution => 'A/AU/AUTHOR/Foo-Bar-1.0.tar.gz' )

Given the name of a package, searches all the repository indexes and
returns the URL to a distribution containing that requested package,
or the distribution you requested.

If you also specify a C<version>, then you'll always get a
distribution that contains that version of the package or higher.  If
you also specify C<latest> then you'll always get the distribution
that contains the latest version of the package that can be found in
all the indexes.  Otherwise you'll just get the first distribution we
can find that satisfies your request.

If you give a distribution path instead, then you'll just get back the
URL to the first distribution we find at that path in any of the
repository indexes.

If neither the package nor the distribution path can be found in any
of the indexes, returns undef.

=cut

sub locate {
    my ($self, %args) = @_;

    $args{spec} || throw 'Invalid arguments';

    $args{spec} = Pinto::Target->new($args{spec}) 
        if not ref $args{spec};

    return $self->_locate_package(%args)
        if $args{spec}->isa('Pinto::Target::Package');

    return $self->_locate_distribution(%args)
        if $args{spec}->isa('Pinto::Target::Distribution');
        
    throw 'Invalid arguments';
}

#------------------------------------------------------------------------------

sub _locate_package {
    my ($self, %args) = @_;

    my $spec   = $args{spec};
    my $latest = $args{latest};

    my ($latest_found_package, $found_in_index);
    for my $index ( $self->indexes() ) {

        my $found_package = $index->packages->{$spec->name};
        next if not $found_package;

        my $found_package_version = version->parse( $found_package->{version} );
        next if not $spec->is_satisfied_by($found_package_version);

        $found_in_index       ||= $index;
        $latest_found_package ||= $found_package;
        last unless $latest;

        ($found_in_index, $latest_found_package) = ($index, $found_package)
            if $self->__compare_packages($found_package, $latest_found_package) == 1;
    }


    if ($latest_found_package) {
        my $base_url = $found_in_index->repository_url;
        my $latest_dist_path = $latest_found_package->{distribution};
        return  URI->new( "$base_url/authors/id/" . $latest_dist_path );
    }

    return;
}

#------------------------------------------------------------------------------

sub _locate_distribution {
    my ($self, %args) = @_;

    my $spec = $args{spec};

    for my $index ( $self->indexes ) {

        my $dist_path = $spec->path;
        my $base_url  = $index->repository_url;
        my $dist_url  = URI->new("$base_url/authors/id/$dist_path");

        return $dist_url if $index->distributions->{$dist_path};
        return $dist_url if $self->repo->ua->head($dist_url)->is_success;
    }

    return;
}

#------------------------------------------------------------------------------

sub __compare_packages {
    my ($self, $pkg_a, $pkg_b) = @_;

    my $pkg_a_version = $self->__versionize( $pkg_a->{version} );
    my $pkg_b_version = $self->__versionize( $pkg_b->{version} );

    # TODO: compare dist mtimes (but they are on the server!)
    return  $pkg_a_version  <=> $pkg_b_version;
}

#------------------------------------------------------------------------------

sub __versionize {
    my ($self, $version) = @_;

    my $v = eval { version->parse($version) };

    return defined $v ? $v : version->new(0);
}

#------------------------------------------------------------------------------

=method clear_cache()

Deletes the cached index files.  Any subsequent calls to the C<locate>
method will cause the index files to be fetched anew.

=cut

sub clear_cache {
    my ($self) = @_;

    for my $index ( $self->indexes() ) {
        $index->index_file->remove();
    }

    $self->clear_indexes();

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__
