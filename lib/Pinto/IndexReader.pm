package Pinto::IndexReader;

# ABSTRACT: Read an 02packages.details file

use Moose;

use Path::Class;
use PerlIO::gzip;

use Pinto::Util;
use Pinto::Types qw(URI);

use Pinto::Exceptions qw(throw_fatal);
use Exception::Class::TryCatch;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Attributes

has source => (
    is       => 'ro',
    isa      => URI,
    required => 1,
);

has distributions => (
   is        => 'ro',
   isa       => 'HashRef',
   default   => sub { {} },
);

has modules => (
   is        => 'ro',
   isa       => 'HashRef',
   default   => sub { {} },
);

#------------------------------------------------------------------------------
# Roles

with qw( Pinto::Interface::Loggable
         Pinto::Role::FileFetcher );

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $source = $self->source();
    my $index_url = "$source/modules/02packages.details.txt.gz";
    my $index_file = $self->fetch_temporary(url => $index_url);

    $self->info("Reading index from $source");
    open my $fh, '<:gzip', $index_file or throw_fatal "Cannot open $index_file: $!";
    my $dists = $self->_read($fh);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _read {
    my ($self, $fh) = @_;

    my $inheader = 1;
    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

        chomp;
        my ($module, $version, $dist_path) = split;
        $self->_add_entry($module, $version, $dist_path);
    }

    return $self;
}

#------------------------------------------------------------------------------

sub _add_entry {
    my ($self, $module, $version, $dist_path) = @_;

    my $ref = $self->distributions()->{$dist_path} ||= [];
    push @$ref, {name => $module, version => $version};
    $self->modules()->{$module} = {version => $version, path => $dist_path};

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------
1;

__END__
