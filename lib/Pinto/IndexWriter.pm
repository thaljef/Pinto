# ABSTRACT: Write records to an 02packages.details.txt file

package Pinto::IndexWriter;

use Moose;

use Path::Class qw(file);
use PerlIO::gzip;

use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw(Pinto::Role::Loggable);

#------------------------------------------------------------------------------
# Methods

sub write {                                       ## no critic (BuiltinHomonym)
    my ($self, %args) = @_;

    my $handle   = $args{handle};
    my $file     = $args{file};
    my $stack    = $args{stack};
    my $nozip    = $args{nozip};
    my $filename;

    throw "Must specify either an output handle or file name"
        if not ($handle xor $file);

    if ($file) {
        my $io_layer = $nozip ? '' : ':gzip';
        open $handle, ">:$io_layer", $file or throw "Cannot open $file: $!";
        $self->info("Writing index for stack $stack at $file");
        $filename = $file;
    }
    else {
        my $fileno = $handle->fileno;
        $self->info("Writing index for stack $stack to handle $handle");
        $filename = file( $handle->can('filename') ? $handle->filename: 'UNKNOWN' );
    }

    my @records = $self->_get_index_records($stack);
    my $count = @records;

    $self->_write_header($handle, $filename, $count);
    $self->_write_records($handle, @records);
    close $handle if $file;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh, $filename, $line_count) = @_;

    my $base    = $filename->basename;
    my $url     = 'file://' . $filename->absolute->as_foreign('Unix');
    my $version = $Pinto::IndexWriter::VERSION || 'UNKNOWN VERSION';

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $base
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   Pinto::IndexWriter $version
Line-Count:   $line_count
Last-Updated: @{[ scalar localtime() ]}

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_records {
    my ($self, $fh, @records) = @_;

    for my $record ( @records ) {
        my ($name, $version, $path) = @{ $record };
        my $width = 38 - length $version;
        $width = length $name if $width < length $name;
        printf {$fh} "%-${width}s %s  %s\n", $name, $version, $path;
    }

    return $self;
}

#------------------------------------------------------------------------------

sub _get_index_records {
    my ($self, $stack) = @_;

    # The index is rewritten after almost every action, so we want
    # this to be as fast as possible (especially during an Add or
    # Remove action).  Therefore, we use a cursor to get raw data and
    # skip all the DBIC extras.

    # Yes, slurping all the records at once consumes a lot of memory,
    # but I want them to be sorted the way perl sorts them, not the
    # way sqlite sorts them.  That way, the index file looks more
    # like one produced by PAUSE.  Also, this is about twice as fast
    # as using an iterator to read each record lazily.

    my $attrs   = {select => [qw(package_name package_version distribution_path)] };
    my $rs      = $stack->search_related_rs('registrations', {}, $attrs);
    my @records =  sort {$a->[0] cmp $b->[0]} $rs->cursor->all;

    return @records;


}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__





