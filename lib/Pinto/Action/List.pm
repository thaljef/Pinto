# ABSTRACT: List the contents of a stack

package Pinto::Action::List;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Types qw(AuthorID StackName StackDefault StackObject);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Colorable );

#------------------------------------------------------------------------------

has stack => (
    is        => 'ro',
    isa       => StackName | StackDefault | StackObject,
    default   => undef,
);


has pinned => (
    is     => 'ro',
    isa    => Bool,
);


has author => (
    is     => 'ro',
    isa    => AuthorID,
);


has packages => (
    is     => 'ro',
    isa    => Str,
);


has distributions => (
    is     => 'ro',
    isa    => Str,
);


has format => (
    is        => 'ro',
    isa       => Str,
    default   => '%m%s%y %-40p %12v %a/%f',
    lazy      => 1,
);


has where => (
    is       => 'ro',
    isa      => HashRef,
    builder  => '_build_where',
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub _build_where {
    my ($self) = @_;

    my $where = {};
    my $stack = $self->repo->get_stack($self->stack);
    $where = {revision => $stack->head->id};

    if (my $pkg_name = $self->packages) {
        $where->{'package.name'} = { like => "%$pkg_name%" }
    }

    if (my $dist_name = $self->distributions) {
        $where->{'distribution.archive'} = { like => "%$dist_name%" };
    }

    if (my $author = $self->author) {
        $where->{'distribution.author'} = uc $author;
    }

    if (my $pinned = $self->pinned) {
        $where->{is_pinned} = 1;
    }

    return $where;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where;
    my $attrs = {prefetch => [ qw(revision package distribution) ]};
    my $rs    = $self->repo->db->schema->search_registration($where, $attrs);

    # I'm not sure why, but the results appear to come out sorted by
    # package name, even though I haven't specified how to order them.
    # This is fortunate, because adding and "ORDER BY" clause is slow.
    # I'm guessing it is because there is a UNIQUE INDEX on package_name
    # in the registration table.

    while ( my $reg = $rs->next ) {
        my $string = $reg->to_string($self->format);

        my $color =   $reg->is_pinned              ? $self->color_3 
                    : $reg->distribution->is_local ? $self->color_1 : undef;

        $string = $self->colorize_with_color($string, $color);
        $self->say($string);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
