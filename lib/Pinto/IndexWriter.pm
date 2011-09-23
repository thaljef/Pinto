package Pinto::IndexWriter;

# ABSTRACT: Write records to an 02packages file

use Moose;
use Moose::Autobox;

use MooseX::Types::Moose qw(HashRef Bool);
use Pinto::Types 0.017 qw(File);

use Carp;
use PerlIO::gzip;
use Path::Class qw();

use Pinto::Exceptions qw(throw_fatal);

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

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Methods

sub write {                                       ## no critic (BuiltinHomonym)
    my ($self, %args) = @_;

    my $file = $args{file};
    $self->info("Writing index at $file");

    open my $fh, '>:gzip', $file or throw_fatal "Cannot open $file: $!";
    $self->_write_header($fh, $file);
    $self->_write_packages($fh);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh, $filename) = @_;

    my $base    = $filename->basename();
    my $url     = 'file://' . $filename->absolute->as_foreign('Unix');
    my $version = $Pinto::IndexWriter::VERSION || 'UNKNOWN VERSION';
    my $count   = $self->db->get_all_indexed_packages->count();

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $base
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::IndexWriter $version
Line-Count:   $count
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_packages {
    my ($self, $fh) = @_;

    # The index is rewritten after almost every action, so
    # we want this to be as fast as possible (especially
    # during an Add or Remove action).  Therefore, we use
    # a cursor to get raw data and skip all the DBIC extras.

    my $indexed = $self->db->get_all_indexed_packages();
    my $cursor  = $indexed->cursor();

    while ( my @vals = $cursor->next() ) {
        my ($name, $version, $path) = @vals;
        my $width = 38 - length $version;
        $width = length $name if $width < length $name;
        printf {$fh} "%-${width}s %s  %s\n", $name, $version, $path;
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__





