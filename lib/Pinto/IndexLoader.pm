package Pinto::IndexLoader;

# ABSTRACT: Load the Pinto database from an 02packages.details file

use Moose;

use Path::Class;
use PerlIO::gzip;

use Pinto::Util;

use Pinto::Exceptions qw(throw_fatal);
use Exception::Class::TryCatch;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has db => (
    is       => 'ro',
    isa      => 'Pinto::Database',
    required => 1,
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Loggable
         Pinto::Role::UserAgent );

#------------------------------------------------------------------------------

sub load {
    my ($self, %args) = @_;
    my $from = $args{from};

    my $index_url = "$from/modules/02packages.details.txt.gz";
    my $index_file = $self->fetch_temporary(url => $index_url);

    $self->info("Loading index from $from");
    open my $fh, '<:gzip', $index_file or throw_fatal "Cannot open $index_file: $!";
    my $dists = $self->_read($fh);
    close $fh;


    foreach my $path ( sort keys %{ $dists } ) {

        if ( $self->db->get_distribution_with_path($path) ) {
            $self->debug("Skipping $path: already loaded");
            next;
        }

        my $dist = $self->db->new_distribution(path => $path, origin => $from);
        $self->db->add_distribution($dist);

        for my $pkg_spec ( @{ $dists->{$path} } ) {
            my $pkg = $self->db->new_package(%{$pkg_spec}, distribution => $dist);
            $self->db->add_package($pkg);
        }
    }

    return $self;
}

#------------------------------------------------------------------------------

sub _read {
    my ($self, $fh) = @_;

    my $data = {};
    my $inheader = 1;
    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

        chomp;
        my ($name, $version, $path) = split;

        $data->{$path} ||= [];
        push @{ $data->{$path} }, {name => $name, version => $version};
    }

    return $data;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
