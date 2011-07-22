package App::Pinto;

# ABSTRACT: Perl archive repository manager

use Moose;

use Pinto::Util;
use Pinto::Index;
use Pinto::Config;
use Pinto::UserAgent;

use Carp;
use File::Copy;
use File::Find;
use Dist::MetaData;
use Path::Class;
use URI;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

has 'profile' => (
    is           => 'ro',
    isa          => 'Str',
);

has 'config' => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    builder  => '_build_config',
    lazy     => 1,
);

has '_ua'      => (
    is         => 'ro',
    isa        => 'Pinto::UserAgent',
    default    => sub { Pinto::UserAgent->new() },
    handles    => [qw(mirror)],
    init_arg   => undef,
);

has 'remote_index' => (
    is             => 'ro',
    isa            => 'Pinto::Index',
    builder        => '_build_remote_index',
    init_arg       => undef,
    lazy           => 1,
);

has 'local_index'   => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '_build_local_index',
    init_arg        => undef,
    lazy            => 1,
);

has 'master_index'  => (
    is              => 'ro',
    isa             => 'Pinto::Index',
    builder         => '_build_master_index',
    init_arg        => undef,
    lazy            => 1,
);

#------------------------------------------------------------------------------
# Roles

with 'Pinto::Role::Log';

#------------------------------------------------------------------------------
# Builders

sub _build_config {
    my ($self) = @_;
    return Pinto::Config->new(profile => $self->profile());
}

#------------------------------------------------------------------------------

sub _build_remote_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.remote.txt.gz');
}

#------------------------------------------------------------------------------

sub _build_local_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.local.txt.gz');
}

#------------------------------------------------------------------------------

sub _build_master_index {
    my ($self) = @_;

    return $self->__build_index(file => '02packages.details.txt.gz');
}

#------------------------------------------------------------------------------

sub __build_index {
    my ($self, %args) = @_;

    my $local = $self->config()->{_}->{local};
    my $index_file = file($local, 'modules', $args{file});

    return Pinto::Index->new(file => $index_file);
}

#------------------------------------------------------------------------------
# Private methods

sub _rebuild_master_index {
    my ($self) = @_;

    $self->master_index()->clear();
    $self->master_index()->add( @{$self->remote_index()->packages()} );
    $self->master_index()->merge( @{$self->local_index()->packages()} );

    return $self->master_index();
}

#------------------------------------------------------------------------------
# Public actions

sub update {
    my ($self, %args) = @_;

    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $remote = $args{remote} || $self->config()->{_}->{remote};

    my $remote_index_uri = URI->new("$remote/modules/02packages.details.txt.gz");
    $self->mirror(url => $remote_index_uri, to => $self->remote_index()->file());
    $self->remote_index()->reload();

    my $changes = 0;
    my $mirrorable_index = $self->remote_index() - $self->local_index();

    for my $file ( @{ $mirrorable_index->files() } ) {
        $self->log()->info("Mirroring $file");
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $destination = Pinto::Util::native_file($local, 'authors', 'id', $file);
        $changes += $self->mirror(url => $remote_uri, to => $destination);
    }

    $self->_rebuild_master_index()->write();

    # TODO: Clean if directed
    return $self;
}

#------------------------------------------------------------------------------

sub clean {
    my ($self, %args) = @_;
    my $local = $args{local} || $self->config()->{_}->{local};
    my $base_dir = dir($local, qw(authors id));

    my $wanted = sub {
        $DB::single = 1;
        my $physical_file = file($File::Find::name);
        my $logical_file  = $physical_file->relative($base_dir)->as_foreign('Unix');

        # TODO: Can we just use $_ instead of calling basename() ?
        if (Pinto::Util::is_source_control_file( $physical_file->basename() )) {
            $File::Find::prune = 1;
            return;
        }

        return if not -f $physical_file;
        return if exists $self->master_index()->packages_by_file()->{$logical_file};
        $self->log()->info("Cleaning $logical_file"); # TODO: report as physical file instead?
        $physical_file->remove(); # TODO: Error check!
    };

    # TODO: Consider using Path::Class::Dir->recurse() instead;
    File::Find::find($wanted, $base_dir);

    return $self;
}

#------------------------------------------------------------------------------

sub remove {
    my ($self, %args) = @_;

    my $package = $args{package};
    my $local   = $args{local}  || $self->config()->{_}->{local};

    my @local_removed = $self->local_index()->remove($package);
    $self->log->info("Removed $_ from local index") for @local_removed;
    $self->local_index()->write();

    my @master_removed = $self->master_index()->remove($package);
    $self->log->info("Removed $_ from master index") for @master_removed;
    $self->master_index()->write();

    # Do not rebuild master index after removing packages,
    # or else the packages from the remote index will appear.

    # TODO: clean, if directed
    return $self;
}

#------------------------------------------------------------------------------

sub add {
    my ($self, %args) = @_;

    my $file   = $args{file};
    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $author = $args{author} || $self->config()->{_}->{author};

    $file = file($file) if not eval { $file->isa('Path::Class::File') };

    my $distmeta = Dist::Metadata->new(file => $file);
    my $provides = $distmeta->package_versions();

    my $author_dir    = Pinto::Util::directory_for_author($author);
    my $file_in_index = file($author_dir, $file->basename())->as_foreign('Unix');

    if (my $existing_file = $self->local_index()->packages_by_file->{$file_in_index}) {
        croak "File '$file_in_index' already exists in the local index";
    }

    my @packages = ();
    while( my ($pkg, $ver) = each %{ $provides } ){
        $self->log->info("Adding $pkg $ver");
        push @packages, Pinto::Package->new(name => $pkg, version => $ver, file => "$file_in_index");
    }

    $self->local_index->add(@packages);
    $self->local_index()->write();

    my $destination_dir = Pinto::Util::directory_for_author($local, qw(authors id), $author);
    $destination_dir->mkpath();  #TODO: log & error check
    copy($file, $destination_dir); #TODO: log & error check

    $self->_rebuild_master_index()->write();

    # TODO: Clean if directed
    return $self;
}

#------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    for my $package ( @{ $self->master_index()->packages() } ) {
        # TODO: Report native paths instead?
        print $package->to_string(), "\n";
    }

    return $self;
}

#------------------------------------------------------------------------------

sub verify {
    my ($self) = @_;
    my $local = $self->config()->{_}->{local};

    my @base = ($local, 'authors', 'id');
    for my $file ( @{ $self->master_index()->files_native(@base) } ) {
        # TODO: Report full or relative path?
        print "$file is missing\n" if not -e $file;
    }

    return $self;
}

#------------------------------------------------------------------------------

1;

__END__
