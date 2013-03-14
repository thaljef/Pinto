# ABSTRACT: Generates a stub 01mailrc.txt.gz file

package Pinto::File::Mailrc;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use IO::Zlib;

use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    required => 1,
);


has mailrc_file  => (
    is      => 'ro',
    isa     => File,
    default => sub { $_[0]->repo->config->authors_dir->file('01mailrc.txt.gz') },
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub write_mailrc {
    my ($self) = @_;

    my $fh = IO::Zlib->new($self->mailrc_file->stringify, 'wb') or throw $!;
    print {$fh} ''; # File will be empty, but have gzip headers
    close $fh or throw $!;

    return $self;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
