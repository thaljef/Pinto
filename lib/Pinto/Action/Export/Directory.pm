# ABSTRACT: support directory storage for Export action

package Pinto::Action::Export::Directory;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;
use Path::Class;

use Pinto::Util qw(mksymlink);
use File::Copy ();

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has path => (
   is => 'ro',
   required => 1,
);

sub insert {
   my ($self, $source, $destination) = @_;
   $destination = $self->path()->file($destination);
   File::Copy::copy($source, $destination);
   return;
}

sub link {
   my ($self, $from, $to) = @_;
   $from = $self->path()->file($from);
   mksymlink($from, $to);
   return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
