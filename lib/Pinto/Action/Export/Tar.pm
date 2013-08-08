# ABSTRACT: support TAR archive storage for Export action

package Pinto::Action::Export::Tar;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;
use Archive::Tar;
use Archive::Tar::Constant qw< SYMLINK >;

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

sub insert {
   my ($self, $source, $destination) = @_;

   return if $self->is_present($source);
   $self->mark($source);

   my ($file) = $self->archive()->add_files($source);
   $file->rename($self->prefix()->file($destination));

   return;
}

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

sub close {
   my ($self) = @_;
   $self->archive()->write($self->exporter()->output());
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
