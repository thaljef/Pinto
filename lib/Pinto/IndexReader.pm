# ABSTRACT: The package index of a repository

package Pinto::IndexReader;

use Moose;
use MooseX::Types::Moose qw(HashRef);
use MooseX::MarkAsMethods (autoclean => 1);

use IO::Zlib;

use Pinto::Types qw(File);
use Pinto::Util qw(throw);

#------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------

has index_file => (
    is         => 'ro',
    isa        => File,
    required   => 1,
);

has packages => (
    is        => 'ro',
    isa       => HashRef,
    builder   => '_build_packages',
    lazy      => 1,
);

#------------------------------------------------------------------------------

sub _build_packages {
    my ($self) = @_;

    my $file = $self->index_file->stringify;
    my $fh = IO::Zlib->new($file, 'rb') or throw "Failed to open index file $file: $!";
    my $index_data = $self->__read_index($fh);
    close $fh;

    return $index_data;
}

#------------------------------------------------------------------------------

sub __read_index {
    my ($self, $fh) = @_;

    my $inheader  = 1;
    my $packages  = {};

    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

        chomp;
        my ($package, $version, $path) = split;
        $packages->{$package} = {name => $package, version => $version, path => $path};
    }

    return $packages
}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------
1;

__END__
