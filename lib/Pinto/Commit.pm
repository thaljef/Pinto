# ABSTRACT: Represents 

package Pinto::Commit;

use Moose;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods (autoclean => 1);

use DateTime;
use String::Format;

use Pinto::Exception qw(throw);
use Pinto::Util qw(itis trim title_text body_text);

use overload ( '""'     => 'to_string',
               '<=>'    => 'numeric_compare',
               fallback => undef );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has raw_commit => (
  is          => 'ro',
  isa         => 'Git::Raw::Commit',
  required    => 1,
);


has id => (
  is          => 'ro',
  isa         => Str,
  init_arg    => undef,
  default     => sub { $_[0]->raw_commit->id },
  lazy        => 1,
);


has id_prefix => (
  is          => 'ro',
  isa         => Str,
  init_arg    => undef,
  default     => sub { substr($_[0]->id, 0, 7) },
  lazy        => 1,
);


has username => (
  is          => 'ro',
  isa         => Str,
  init_arg    => undef,
  default     => sub { $_[0]->raw_commit->committer->name },
  lazy        => 1,
);


has time => (
  is          => 'ro',
  isa         => 'DateTime',
  init_arg    => undef,
  default     => sub { DateTime->from_epoch(epoch => $_[0]->raw_commit->time) },
  lazy        => 1,
);


has message => (
  is          => 'ro',
  isa         => Str,
  init_arg    => undef,
  default     => sub { trim( $_[0]->raw_commit->message ) },
  lazy        => 1,
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

sub numeric_compare {
  my ($commit_a, $commit_b) = @_;

  my $class = __PACKAGE__;
    throw "Can only compare $class objets"
        unless itis($commit_a, $class) && itis($commit_b, $class);

  return 0 if $commit_a->id eq $commit_b->id;

  return $commit_a->time <=> $commit_b->time;
}

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

    return '%i';
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__
