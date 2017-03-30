# ABSTRACT: Create a new stack by cloning from another repository

package Pinto::Action::Clone;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(StackName StackObject Uri);
use Pinto::IndexReader;
use Pinto::Target::Distribution;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller Pinto::Role::UserAgent );

#------------------------------------------------------------------------------

has upstream => (
    is       => 'ro',
    isa      => Uri,
    required => 1,
    coerce   => 1,
);

has to_stack => (
    is        => 'ro',
    isa       => StackName,
    required  => 1,
);

has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has lock => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

#------------------------------------------------------------------------------

around BUILD => sub {
    my ( $orig, $self ) = @_;

    # XXX this is a bit of a hack. could not get it to work with just 'stack'
    my $stack = $self->repo->create_stack( name => $self->to_stack );
    $self->_set_stack($stack);

    return $self->$orig;
};

#------------------------------------------------------------------------------

sub generate_message_title {
    my ( $self ) = @_;
    return join ' ', 'Clone', $_[0]->upstream->as_string, 'to', $_[0]->stack;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    # get the distribution paths from the upstream index
    my $index = $self->mirror_temporary(
        $self->upstream . '/modules/02packages.details.txt.gz'
    );
    my $reader = Pinto::IndexReader->new(index_file => $index);
    my %paths = (
      map { $_->{path} => 1 }               # remove duplicates
      grep { $_->{path} !~ m{F/FA/FAKE/perl-} } # skip the fake perl modules
      values %{ $reader->packages }
    );

    # pull down all the corresponding distributions
    # note: we are not using upstream as a source
    my $stack = $self->stack;
    for my $path (keys %paths) {
        $path =~ s{\w/\w\w/}{};
        $self->notice( "Pulling target $path to stack $stack");
        my $dist = Pinto::Target::Distribution->new($path);
        $self->pull(target => $dist);
    }

    # finalise the stack
    my $upstream = $self->upstream->as_string;
    my $description =
          $self->has_description
        ? $self->description
        : "Clone of stack from $self->upstream";

    $stack->set_description($description);
    $stack->mark_as_default if $self->default;
    $stack->lock            if $self->lock;

    $self->chrome->progress_done;

    return $self->result->changed;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
