# ABSTRACT: support ZIP archive storage for Export action

package Pinto::Action::Export::Zip;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;
use Archive::Zip qw< :ERROR_CODES :CONSTANTS >;

use Pinto::Util qw(mksymlink);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has archive => (
   is => 'ro',
   default => sub {
      my $archive = Archive::Zip->new();
      return $archive;   
   },
);

has prefix => (
   is => 'ro',
   lazy => 1,
   default => sub {
      my ($self) = @_;
      return dir($self->exporter()->prefix() || '');
   },
);

sub insert {
   my ($self, $source, $destination) = @_;

   return if $self->is_present($source);
   $self->mark($source);

   $destination = $self->prefix()->file($destination);
   my $file = $self->archive()->addFile("$source", "$destination");
   $file->desiredCompressionMethod(COMPRESSION_STORED);

   return;
}

sub link {
   die "ZIP output format does not support exporting multiple stacks\n";
}

sub close {
   my ($self) = @_;
   my $output = $self->exporter()->output();
   $self->archive()->writeToFileNamed("$output");
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
