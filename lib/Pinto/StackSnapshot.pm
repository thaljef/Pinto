# ABSTRACT: A stack at a past revision

package Pinto::StackSnapshot;

use Moose;
use MooseX::Types::Moose qw(Int ArrayRef);

use String::Format;

use Pinto::RegistrationSnapshot;
use Pinto::Exception qw(throw);

use overload ( '""'  => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has stack  => (
    is         => 'ro',
    isa        => 'Pinto::Schema::Result::Stack',
    required   => 1,
);


has revision  => (
    is        => 'ro',
    isa       => Int,
    default   => sub { $_[0]->stack->head_revision->number },
    lazy      => 1,
);


has registrations => (
    isa       => ArrayRef,
    traits    => [ qw(Array) ],
    handles   => {registrations => 'elements'},
    builder   => '_build_registrations',
    lazy      => 1,
);

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    my $revnum = $self->revision;
    my $stack  = $self->stack;

    throw "Revision number must be positive" 
      if $revnum < 0;
    
    throw "Revision $revnum of stack $stack does not exist yet" 
      if $revnum > $stack->head_revision->number;

    return $self;
}

#------------------------------------------------------------------------------

sub _build_registrations {
    my ($self) = @_;

    # TODO: Maybe optimize by selecting only the IDs (probably using a cursor)
    # and then query for the full package objects only after doing all the
    # adds and deletes.  This presumes that many of the records retrieved will
    # get tossed out as we unwind the revision history.  So why bother creating
    # the entire Package object until we know exactly which Packages will actually
    # be in the Snapshot.  Once you have the final list of IDs, then you can
    # get all the corresponding objects in one query.

    $DB::single = 1;
    my %structs   = $self->_head_structs;
    my @revisions = $self->_past_revisions;

    for my $revision (@revisions) {
 
        # Reinflating as hash to avoid extra query to get the package id below
        my $attrs = {result_class => 'DBIx::Class::ResultClass::HashRefInflator'};
        my @changes = $revision->kommit->registration_changes({}, $attrs);
 
        for my $change ( reverse @changes ) {

            my $pkg   = $change->{package_name};
            my $event = $change->{event};

            if ($event eq 'delete') {
                $structs{$pkg} = { pkg_id    => $change->{package}, 
                                   is_pinned => $change->{is_pinned} };
            }
            elsif ($event eq 'insert') {
                delete $structs{$pkg};
            }
            else {
                throw "Don't know how to handle event $event";
            }
        }
    }

    # Gather up the IDs for all the packages in the structs and fetch
    # the corresponding Package objects from the database.
    my @pkg_ids  = sort map { $_->{pkg_id} } values %structs;
    my $where    = {'me.id' => {-in => \@pkg_ids}};
    my $attrs    = {prefetch => 'distribution'};
    my $schema   = $self->stack->result_source->schema;
    my @pkg_objs = $schema->resultset('Package')->search($where, $attrs);

    # Now replace the IDs in the structs with the actual package objects
    for my $pkg_obj (@pkg_objs) {

        my $pkg_name = $pkg_obj->name;
        my $struct   = $structs{$pkg_name};

        # Assertions to ensure I've dont this right
        defined $struct or throw "Somethig is amiss";
        delete  $struct->{pkg_id} == $pkg_obj->id or throw "Something is amiss";

        # Inject package back into the struct
        $struct->{package} = $pkg_obj;
    }

    $DB::single = 1;
    # Finally turn all the structs into RegistrationShapshot objects
    my @registrations = map { Pinto::RegistrationSnapshot->new($_) } 
        @structs{ sort keys %structs };

    return \@registrations;
}

#------------------------------------------------------------------------------

sub _head_structs {
    my ($self) = @_;

    my $attrs   = {select => [ qw(package_name package is_pinned) ]};
    my @head    = $self->stack->registrations({}, $attrs)->cursor->all;
    my %structs = map { ($_->[0] => {pkg_id    => $_->[1], 
                                     is_pinned => $_->[2]}) } @head;

    return %structs;   
}

#------------------------------------------------------------------------------

sub _past_revisions {
    my ($self) = @_;

    my $attrs = {prefetch => {kommit => 'registration_changes'}};
    my $where = {'me.number' => { '>' => $self->revision}};
    my @revisions = $self->stack->revisions($where, $attrs);

    return reverse @revisions;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    return join "\n", $self->registrations;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__

