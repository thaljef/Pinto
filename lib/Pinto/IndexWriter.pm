# ABSTRACT: Write records to an 02packages.details.txt file

package Pinto::IndexWriter;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use IO::Zlib;
use Path::Class qw(file);
use HTTP::Date qw(time2str);

use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Stack',
    required => 1,
);


has index_file  => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->stack->modules_dir->file('02packages.details.txt.gz') },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub write_index {
    my ($self) = @_;

    my $index_file  = $self->index_file;
    my $stack = $self->stack;

    $self->info("Writing index for stack $stack at $index_file");

    my $handle = IO::Zlib->new($index_file->stringify, 'wb') 
        or throw "Cannot open $index_file: $!";

    my @records = $self->_get_index_records($stack);
    my $count   = scalar @records;

    $self->_write_header($handle, $index_file, $count);
    $self->_write_records($handle, @records);
    close $handle;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh, $filename, $line_count) = @_;

    my $base    = $filename->basename;
    my $url     = 'file://' . $filename->absolute->as_foreign('Unix');

    my $writer  = ref $self;
    my $version = $self->VERSION || 'UNKNOWN';
    my $date    = time2str(time);

    print {$fh} <<"END_PACKAGE_HEADER";
File:         $base
URL:          $url
Description:  Package names found in directory \$CPAN/authors/id/
Columns:      package name, version, path
Intended-For: Automated fetch routines, namespace documentation.
Written-By:   $writer version $version
Line-Count:   $line_count
Last-Updated: $date

END_PACKAGE_HEADER

    return $self;
}

#------------------------------------------------------------------------------

sub _write_records {
    my ($self, $fh, @records) = @_;

    for my $record ( @records ) {
        my ($name, $version, $author, $archive) = @{ $record };
        my $path = join '/', substr($author, 0, 1), substr($author, 0, 2), $author, $archive;
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

    my @joins   = qw(package distribution);
    my @selects = qw(package.name package.version distribution.author distribution.archive);

    my $attrs   = {join => \@joins, select => \@selects};
    my $rs      = $stack->head->search_related('registrations', {}, $attrs);
    my @records = sort {$a->[0] cmp $b->[0]} $rs->cursor->all;

    return @records;


}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
