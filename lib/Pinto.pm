package Pinto;

use Moose;

use Pinto::Util::Svn qw(:all);
use Pinto::UserAgent;
use Pinto::Index;

use File::Copy;
use Dist::MetaData;
use Path::Class;
use URI;

#------------------------------------------------------------------------------

has 'config' => (
    is       => 'ro',
    isa      => 'Pinto::Config',
    required => 1,
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

#------------------------------------------------------------------------------

sub _build_remote_index {
    my ($self) = @_;
    my ($local) = $self->config->{_}->{local};
    my $remote_index_file = file($local, 'modules', "02packages.details.remote.txt.gz");
    return Pinto::Index->new(source => $remote_index_file);
}

#------------------------------------------------------------------------------

sub _build_local_index {
    my ($self) = @_;
    my $local = $self->config->{_}->{local};
    my $local_index_file = file($local, 'modules', "02packages.details.local.txt.gz");
    return Pinto::Index->new(source => "$local_index_file");
}

#------------------------------------------------------------------------------


sub upgrade {
    my ($self, %args) = @_;

    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $remote = $args{remote} || $self->config()->{_}->{remote};

    my $remote_index_uri = URI->new("$remote/modules/02packages.details.txt.gz");
    $self->mirror(url => $remote_index_uri, to => $self->remote_index()->source());

    $self->remote_index()->reload();
    $self->remote_index()->remove(@{ $self->local_index()->packages() });

    my $changes = 0;
    for my $file ( @{ $self->remote_index()->files() } ) {
        print "Mirroring $file\n";
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $destination = file($local, 'authors', 'id', $file);
        $changes += $self->mirror(url => $remote_uri, to => $destination);
    }


    $self->remote_index()->merge(@{ $self->local_index()->packages() });
    my $merged_index_file = file($local, 'modules', "02packages.details.txt.gz");
    $self->remote_index()->write(file => $merged_index_file);

    return $self;
}


#------------------------------------------------------------------------------

sub add {
    my ($self, %args) = @_;
    my $file   = $args{file};
    my $local  = $args{local}  || $self->config()->{_}->{local};
    my $author = $args{author} || $self->config()->{_}->{author};

    $file = file($file) if not eval { $file->isa('Path::Class') };

    my @packages = $self->extract_packages(file => $file, author => $author);
    printf "Adding %s %s\n", $_->name(), $_->version() for @packages;
    $self->local_index->add(@packages);
    $self->local_index()->write();

    my $authordir = dir($local, 'authors', 'id', _author_directory($author));
    $authordir->mkpath();  #TODO: log & error check
    copy($file, $authordir); #TODO: log & error check

    $self->remote_index->merge( @{ $self->local_index()->packages() } );
    my $merged_index_file = file($local, 'modules', "02packages.details.txt.gz");
    $self->remote_index()->write(file => $merged_index_file);

}

#------------------------------------------------------------------------------

sub list {
    my ($self) = @_;

    $self->remote_index()->merge( @{ $self->local_index()->packages() } );
    for my $package ( @{ $self->remote_index()->packages() } ) {
        print $package->to_string(), "\n";
    }

    return $self;
}

#------------------------------------------------------------------------------

sub _author_directory {
    my ($author) = @_;
    $author = uc $author;
    return dir(substr($author, 0, 1), substr($author, 0, 2), $author);
}

#------------------------------------------------------------------------------

sub extract_packages {
    my ($self, %args) = @_;
    my $file = $args{file};
    my $author = $args{author};

    my $author_dir = _author_directory($author);
    my $local_file = file($author_dir, $file->basename());

    my $distmeta = Dist::Metadata->new(file => $file);
    my $provides = $distmeta->package_versions();

    my @packages = ();
    while( my ($pkg, $ver) = each %{ $provides } ){
        push @packages, Pinto::Package->new(name => $pkg, version => $ver, file => $local_file);
    }

    return @packages;
}

#------------------------------------------------------------------------------

1;

=pod

=head1 NAME

Pinto - The personal Perl archive manager

=cut
