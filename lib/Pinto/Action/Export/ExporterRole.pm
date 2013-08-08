# ABSTRACT: role for Exporters

package Pinto::Action::Export::ExporterRole;

use Moose::Role;
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

has exporter => (
   is => 'ro',
   required => 1,
);

has _is_present => (
   is => 'ro',
   default => sub { return {} },
);

has path => (
   is => 'ro',
   default => sub {
      my $self = shift;
      my $output = $self->exporter()->output();
      return dir($output)
         if $self->exporter()->output_format() eq 'directory';
      return file($output);
   },
);

sub is_present {
   my ($self, $what) = @_;
   return exists $self->_is_present()->{$what};
}

sub mark {
   my ($self, $what) = @_;
   $self->_is_present()->{$what} = 1;
}

#------------------------------------------------------------------------------

1;

__END__
