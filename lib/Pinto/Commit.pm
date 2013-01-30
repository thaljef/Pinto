# ABSTRACT: Represents 

package Pinto::Commit;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use String::Format;

use overload ( '""'  => 'to_string' );

#------------------------------------------------------------------------------

has id => (
  is          => 'ro',
  isa         => Str,
  required    => 1,
);


has id_prefix => (
  is          => 'ro',
  isa         => Str,
  lazy        => 1,
  default     => sub { substr($_[0]->id, 0, 7) },
);


has username => (
  is          => 'ro',
  isa         => Str,
  required    => 1,
);


has time => (
  is          => 'ro',
  isa         => 'DateTime',
  required    => 1,
);


has message => (
  is          => 'ro',
  isa         => Str,
  required    => 1,
);



has message_title => (
  is          => 'ro',
  isa         => Str,
  lazy        => 1,
  default     => sub { ... }, # TODO
);


has message_body => (
  is          => 'ro',
  isa         => Str,
  lazy        => 1,
  default     => sub { ... }, # TODO
);

#------------------------------------------------------------------------------

sub to_string {
    my ($self, $format) = @_;

    my %fspec = (
           I => sub { $self->id                          },
           i => sub { $self->id_prefix                   },
           j => sub { $self->username                    },
           u => sub { $self->time->strftime('%c')        },
           g => sub { $self->message_title               },
           G => sub { my $indent = ' ' x (shift || 0); 
                      $self->message =~ s/^/$indent/rg   },
    );

    $format ||= $self->default_format;
    return String::Format::stringf($format, %fspec);
}

#-------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%i: %g';
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
