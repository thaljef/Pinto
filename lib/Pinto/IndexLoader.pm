package Pinto::IndexLoader;

# ABSTRACT: Load the Pinto database from an 02packages file

use Moose;

use autodie;

use Path::Class;
use PerlIO::gzip;

use Pinto::Util;

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

    $self->info("Loading index from $index_file");
    open my $fh, '<:gzip', $index_file;
    my $dists = $self->_read($fh);
    close $fh;


    foreach my $path ( sort keys %{ $dists } ) {

        next if $self->db->get_distribution_with_path($path);

        $self->debug("Distribution $path");
        my $attrs = {path => $path, origin => $from};
        my $dist  = $self->db->add_distribution($attrs);

        foreach my $pkg ( @{ $dists->{$path} } ) {
            $self->debug("Package $pkg->{name}");
            $pkg->{distribution} = $dist->id();
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
