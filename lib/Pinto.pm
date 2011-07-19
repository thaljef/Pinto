package Pinto;

use Moose;

use Pinto::UserAgent;
use Pinto::Index;

use Pinto::Util::Svn qw(:all);
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
    my $remote_index_file = file($local, 'modules', "02packages.details.remote.txt.gz");
    $self->mirror(url => $remote_index_uri, to => $remote_index_file);


    $self->remote_index()->reload();
    $self->remote_index()->remove(@{ $self->local_index()->packages() });

    my $changes = 0;
    for my $file ( @{ $self->remote_index()->files() } ) {
        print "Mirroring $file\n";
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $local_destination = file($local, 'authors', 'id', $file);
        $changes += $self->mirror(url => $remote_uri, to => $local_destination);
    }


    $self->remote_index()->merge(@{ $self->local_index()->packages() });
    my $merged_index_file = file($local, 'modules', "02packages.details.txt.gz");
    $self->remote_index()->write_to_file($merged_index_file);

    return $self;
}


#------------------------------------------------------------------------------

sub add {
    my ($self, %args) = @_;
    my $local = $args{local};
    my $file  = $args{file};

    my @packages = $self->extract_packages($file);
    $self->local_index->add(@packages);
    #$self->local_index()->write_to_file($local_index_file);

    $self->remote_index->merge( @{ $self->local_index()->packages() } );
    my $merged_index_file = file($local, 'modules', "02packages.details.txt.gz");
    $self->remote_index()->write_to_file($merged_index_file);

}

sub extract_packages {
    my ($self, $file) = @_;
}

#------------------------------------------------------------------------------

1;

=pod

=head1 NAME

Pinto - The personal Perl archive manager

=cut
