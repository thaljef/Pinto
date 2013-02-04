# ABSTRACT: Represents 

package Pinto::Commit;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use DateTime;
use String::Format;

use Pinto::Util qw(itis trim title_text body_text);

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
  default     => sub { trim( title_text($_[0]->message) ) },
);


has message_body => (
  is          => 'ro',
  isa         => Str,
  lazy        => 1,
  default     => sub { trim( body_text($_[0]->message) ) },
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
  my ($orig, $class, @args) = @_;

  if ( @args == 1 && itis($args[0], 'Git::Raw::Commit') ) {

    my $git_commit = $args[0];
    my $datetime = DateTime->from_epoch(epoch => $git_commit->time);

    return $class->$orig( id       => $git_commit->id,
                          time     => $datetime,
                          message  => $git_commit->message,
                          username => $git_commit->committer->name );
  }

  return $class->$orig(@args);
};

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
                      $self->message =~ s/^/$indent/mrg  },
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
