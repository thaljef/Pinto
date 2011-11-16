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
    my $reader = $args{reader};

    my $dists = $reader->distributions();
    for my $dist_path ( sort keys %{ $dists } ) {

        if ( $self->db->get_distribution_with_path($dist_path) ) {
            $self->debug("Skipping $dist_path: already loaded");
            next;
        }

        my @package_specs =  @{ $dists->{$dist_path} };
        my $dist = $self->db->new_distribution(path => $dist_path, source => $reader->source());
        my @packages = map { $self->db->new_package(%{$_}) } @package_specs;
        $self->db->add_distribution_with_packages($dist, @packages);
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
