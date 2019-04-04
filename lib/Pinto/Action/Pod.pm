# ABSTRACT: List the contents of a stack

package Pinto::Action::Pod;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(HashRef Str Bool);

use Pinto::Constants qw(:color);
use Pinto::Types qw(AuthorID StackName StackDefault StackObject);
use Pinto::ArchiveUnpacker;
use Pod::ProjectDocs;

#------------------------------------------------------------------------------

our $VERSION = '0.090'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault | StackObject,
    default => undef,
);

has pinned => (
    is  => 'ro',
    isa => Bool,
);

has author => (
    is     => 'ro',
    isa    => AuthorID,
    coerce => 1,
);

has packages => (
    is  => 'ro',
    isa => Str,
);

has distributions => (
    is  => 'ro',
    isa => Str,
);

has local_only => (
    is  => 'ro',
    isa => Bool,
);

has output => (
    is  => 'ro',
    isa => 'Str',
);

has where => (
    is      => 'ro',
    isa     => HashRef,
    builder => '_build_where',
    lazy    => 1,
);

#------------------------------------------------------------------------------

sub _build_where {
    my ($self) = @_;

    my $where = {};
    my $stack = $self->repo->get_stack( $self->stack );
    $where = { revision => $stack->head->id };

    if ( my $pkg_name = $self->packages ) {
        $where->{'package.name'} = { like => "%$pkg_name%" };
    }

    if ( my $dist_name = $self->distributions ) {
        $where->{'distribution.archive'} = { like => "%$dist_name%" };
    }

    if ( my $author = $self->author ) {
        $where->{'distribution.author'} = uc $author;
    }

    if ( my $pinned = $self->pinned ) {
        $where->{is_pinned} = 1;
    }
    
    if ( $self->local_only ) {
        $where->{'distribution.source'} = 'LOCAL';
    }

    return $where;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $where = $self->where;
    my $attrs = {
        prefetch => [qw(revision package distribution)],
        group_by => 'distribution.archive'
    };
    my $rs = $self->repo->db->schema->search_registration( $where, $attrs );

    # I'm not sure why, but the results appear to come out sorted by
    # package name, even though I haven't specified how to order them.
    # This is fortunate, because adding and "ORDER BY" clause is slow.
    # I'm guessing it is because there is a UNIQUE INDEX on package_name
    # in the registration table.

    my @dirs;
    my @unpackers;
    while ( my $reg = $rs->next ) {
        my $color =
              $reg->is_pinned              ? $PINTO_COLOR_1
            : $reg->distribution->is_local ? $PINTO_COLOR_0
            :                                undef;

        $self->show( $reg->distribution->native_path, { color => $color } );
        
        my $unpacker = Pinto::ArchiveUnpacker->new(
            archive => $reg->distribution->native_path,
        );
        
        # keep it in scope so it doesn't get cleaned up too soon
        push @unpackers, $unpacker;
        
        my $temp_dir = $unpacker->unpack;
        push @dirs, "$temp_dir/lib" if -e "$temp_dir/lib"
    }

    my $pd = Pod::ProjectDocs->new(
        outroot => $self->output,
        libroot => [ @dirs ],
        title   => 'ProjectName',
    );
    $pd->gen;

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

