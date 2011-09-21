package Pinto::IndexWriter;

# ABSTRACT: Write records to an 02packages file

use Moose;
use Moose::Autobox;

use MooseX::Types::Moose qw(HashRef Bool);
use Pinto::Types 0.017 qw(File);

use Carp;
use PerlIO::gzip;
use Path::Class qw();

use Pinto::Package;
use Pinto::Distribution;
use Pinto::Exceptions qw(throw_io);

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

    open my $fh, '>:gzip', $file or throw_io "Cannot open $file: $!";
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

    my $rs = $self->db->get_all_indexed_packages();

    while ( my $pkg = $rs->next() ) {
        print {$fh} $pkg->to_index_string();
    }

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------

1;

__END__





