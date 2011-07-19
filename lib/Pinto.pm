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
    init_arg   => undef,
);

#------------------------------------------------------------------------------

sub upgrade {
    my ($self) = @_;

    $DB::single = 1;
    my $url    = $self->config->{_}->{svn_trunk_url};
    my $local  = $self->config->{_}->{local};
    my $remote = $self->config->{_}->{remote};

    svn_checkout(url => $url, to => $local);

    my $local_index_file = file($local, 'modules', "02packages.details.local.txt.gz");
    my $local_index = Pinto::Index->new(source => "$local_index_file");

    my $remote_index_uri = URI->new("$remote/modules/02packages.details.txt.gz");
    my $remote_index_file = file($local, 'modules', "02packages.details.remote.txt.gz");
    $self->_ua()->mirror(url => $remote_index_uri, to => $remote_index_file);

    my $remote_index = Pinto::Index->new(source => $remote_index_file);
    $remote_index->remove(@{ $local_index->packages() });


    $self->_do_upgrade($remote, $local, $remote_index);


    $remote_index->add(@{ $local_index->packages() });
    $remote_index->write_to_file(file($local, 'modules', "02packages.details.txt.gz"));


    #svn_schedule(path => $wc);
    #my $message = "Updated mirror";
    #svn_commit(paths => $wc, message => $message);

    return $self;
}

sub clean {

}

sub _do_upgrade {
    my ($self, $remote, $local, $index) = @_;
    my $ua = $self->_ua();
    my $changes = 0;

    for my $file ( @{ $index->files() } ) {
        print "Mirroring $file\n";
        my $remote_uri = URI->new( "$remote/authors/id/$file" );
        my $local_destination = file($local, 'authors', 'id', $file);
        $changes += $ua->mirror(url => $remote_uri, to => $local_destination);
    }

    return $changes;
}

#------------------------------------------------------------------------------

1;

=pod

=head1 NAME

Pinto - The personal Perl archive manager

=cut
