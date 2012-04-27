package Pinto::IndexWriter;

# ABSTRACT: Write records to an 02packages.details.txt file

use Moose;

use PerlIO::gzip;

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

    my $file  = $args{file};
    my $stack = $args{stack} || 'default';

    $self->info("Writing index for stack $stack at $file");

    my @records = $self->_get_index_records($stack);
    my $count = @records;

    open my $fh, '>:gzip', $file or $self->fatal("Cannot open $file: $!");
    $self->_write_header($fh, $file, $count);
    $self->_write_records($fh, @records);
    close $fh;

    return $self;
}

#------------------------------------------------------------------------------

sub _write_header {
    my ($self, $fh, $filename, $line_count) = @_;

    my $base    = $filename->basename();
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

    my $where  = { 'stack.name' => $stack };
    my $select = [ qw(name version path) ];
    my $attrs  = { select => $select, join => 'stack' };

    my $records = $self->db->select_registries( $where, $attrs );
    my @records =  sort {$a->[0] cmp $b->[0]} $records->cursor->all;

    return @records;

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__





