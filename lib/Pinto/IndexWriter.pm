# ABSTRACT: Writes the 02packages.details.txt.gz file

package Pinto::IndexWriter;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);

use PerlIO::gzip;
use HTTP::Date qw(time2str);

use Pinto::Exception qw(throw);
use Pinto::Types qw(File);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Loggable );

#------------------------------------------------------------------------------

has file  => (
    is        => 'ro',
    isa       => File,
    required  => 1,
);


has entries => (
    is      => 'ro',
    isa     => ArrayRef[ 'Pinto::RegistryEntry' ],
    default => sub { [] },
);

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $file  = $self->file;
    $self->info("Writing index file at $file");

    open my $handle, ">:gzip", $file or throw "Cannot open $file: $!";

    $self->_write_header($handle);
    $self->_write_entries($handle);

    close $handle;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh) = @_;

    my $base    = $self->file->basename;
    my $url     = 'file://' . $self->file->absolute->as_foreign('Unix');
    my $version = $Pinto::IndexWriter::VERSION || 'UNKNOWN VERSION';
    my $count   = scalar @{ $self->entries };

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $base
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::IndexWriter $version
Line-Count:   $count
Last-Updated: @{[ time2str(time) ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_entries {
    my ($self, $fh) = @_;

    my $format = "%-24p %12v %-48h\n";
    print { $fh } $_->to_string($format) for @{ $self->entries };

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__





