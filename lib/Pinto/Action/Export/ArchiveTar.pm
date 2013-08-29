# ABSTRACT: support TAR archive storage for Export action, via Archive::Tar

package Pinto::Action::Export::ArchiveTar;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;
use Archive::Tar;
use Archive::Tar::Constant qw< SYMLINK COMPRESS_GZIP COMPRESS_BZIP >;

use Pinto::Util qw(mksymlink);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has archive => (
   is => 'ro',
   default => sub { return Archive::Tar->new(); },
);

has prefix => (
   is => 'ro',
   lazy => 1,
   default => sub {
      my ($self) = @_;
      return dir($self->exporter()->prefix() || '');
   },
);

#------------------------------------------------------------------------------

sub insert {
   my ($self, $source, $destination) = @_;

   return if $self->is_present($source);
   $self->mark($source);

   my ($file) = $self->archive()->add_files($source);
   $file->rename($self->prefix()->file($destination));

   return;
}

#------------------------------------------------------------------------------

sub link {
   my ($self, $from, $to) = @_;
   $self->archive()->add_data(
      $self->prefix()->file($from),
      '',
      {
         type => SYMLINK,
         linkname => $to,
      }
   );
   return;
}

#------------------------------------------------------------------------------

sub close {
   my ($self) = @_;
   my @compression;
   push @compression, COMPRESS_GZIP
      if $self->exporter()->output_format() =~ /gz$/mxs;
   push @compression, COMPRESS_BZIP
      if $self->exporter()->output_format() eq 'tar.bz2';
   $self->archive()->write($self->exporter()->output(), @compression);
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
