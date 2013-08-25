# ABSTRACT: support TAR archive storage for Export action, via system tar

package Pinto::Action::Export::SystemTar;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;
use File::Which qw< which >;
use File::Temp qw< tempdir >;

use Pinto::Util qw(mksymlink);
use Pinto::Action::Export::Directory;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with 'Pinto::Action::Export::ExporterRole';

has base => (
   is => 'ro',
   default => sub { dir(tempdir(CLEANUP => 1)) },
);

has archive => (
   is => 'ro',
   lazy => 1,
   default => sub {
      my $self = shift;
      my $base = dir($self->base());
      return Pinto::Action::Export::Directory->new(
         path => $base->subdir($self->prefix()),
         exporter => $self->exporter(),
      );
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

has tar => (
   is => 'ro',
   default => sub {
      
   
   
   'tar'
   },
);

sub _check_tar {
   
}

#------------------------------------------------------------------------------

sub insert { # proxy to archive
   my ($self, $source, $destination) = @_;
   return $self->archive()->insert($source, $destination);
}

#------------------------------------------------------------------------------

sub link { # proxy to archive
   my ($self, $from, $to) = @_;
   return $self->archive()->link($from, $to);
}

#------------------------------------------------------------------------------

sub close {
   my ($self) = @_;

   my $base = $self->base();
   my $compression = $self->compression_type();
   my $tar = $self->tar();

   system {$tar} $tar, "c${compression}f", $self->path(),
      '-C', $base, map { $_->basename() } $base->children();

   return;
}

#------------------------------------------------------------------------------

sub compression_type {
   my ($self) = @_;
   my $of = ;
   return {
      'tar.gz'  => 'z',
      'tgz'     => 'z',
      'tar.bz2' => 'j',
      'tbz'     => 'j',
   }->{$self->exporter()->output_format()} || '';
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
