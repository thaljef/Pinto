# ABSTRACT: Compute difference between two revisions

package Pinto::Difference;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has left => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Revision',
    required => 1,
);


has right => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Revision',
    required => 1,
);


has diffs => (
    is       => 'ro',
    isa      => ArrayRef,
    builder  => '_build_diffs',
    init_arg => undef,
    lazy     => 1,
);


has adds => (
    is       => 'ro',
    isa      => ArrayRef['Pinto::Schema::Result::Registration'],
    default  => sub { map { $_->[1] } grep {$_->[0] eq '+'} @{ $_[0]->diffs } }, 
    init_arg => undef,
    lazy     => 1,
);


has dels => (
    is       => 'ro',
    isa      => ArrayRef['Pinto::Schema::Result::Registration'],
    default  => sub { map { $_->[1] } grep {$_->[0] eq '-'} @{ $_[0]->diffs } }, 
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $args  = $class->$orig(@_);

    # The left and right attributes can also be Stack or Revision
    # objects.  In that case, we just convert it to the right thing.

    for my $side ( qw(left right) ) {
        if ($args->{$side}->isa('Pinto::Schema::Result::Stack')) {
            $args->{$side} = $args->{$side}->head;
        }
    }

    return $args;
};

#------------------------------------------------------------------------------

sub _build_diffs {
    my ($self) = @_;


    # We want to find the registrations that are "different" in either 
    # side.  Two registrations are the same if they have the same values in
    # the package, distribution, and is_pinned columns.  So we use these
    # columns to construct the keys of a hash.  The value is the id of
    # the registration.

    my @fields = qw(distribution package is_pinned);

    my $cb = sub {
        my $value = $_[0]->id;
        my $key   = join '|', map {$_[0]->get_column($_)} @fields;
        return ($key => $value);
    };

    my $attrs = {select => ['id', @fields]};
    my %left  = $self->left->registrations({},  $attrs)->as_hash($cb);
    my %right = $self->right->registrations({}, $attrs)->as_hash($cb);

    # Now that we have hashes representing the left and right, we use
    # the keys as "sets" and compute the difference between them.  Keys
    # present on the right but not on the left have been added.  And
    # those present on left but not on the right have been deleted.

    my @add_ids = @right{ grep { not exists $left{$_}  } keys %right };
    my @del_ids = @left{  grep { not exists $right{$_} } keys %left  };

    # Now we have the ids of all the registrations that were added or
    # deleted between the left and right revisions.  We use those ids to
    # requery the database and get full objects for each of them.  Since
    # the number of changed registrations is usually much less than the
    # total number of registrations in either revision, this is much
    # quicker than querying full o

    my $where1     = {'me.id' => {in => \@add_ids}};
    my $add_rs     = $self->right->registrations($where1);
    my @adds = map { ['+' => $_] } $add_rs->with_distribution->with_package;


    my $where2     = {'me.id' => {in => \@del_ids}};
    my $del_rs     = $self->left->registrations($where2);
    my @dels = map { ['-' => $_] } $del_rs->with_distribution->with_package;

    # Strictly speaking, the registrations are an unordered list.  But
    # the diff is more readable if we group registrations together by
    # distribution name.

    my @diffs = sort {
        ($a->[1]->distribution->name  cmp $b->[1]->distribution->name) 
    } @adds, @dels;

    return \@diffs;
}

#------------------------------------------------------------------------------

sub foreach {
    my ($self, $cb) = @_;

    for my $diff ( @{ $self->diffs } ){
        my ($op, $reg) = @{$diff};
        $cb->($op, $reg); 
    }

    return $self;
}

#------------------------------------------------------------------------------

sub to_string {
    my ($self) = @_;

    my $string = '';
    my $format = "[%F] %-40p %12v %a/%f\n";
    my $cb = sub { $string .= $_[0] . $_[1]->to_string($format)};
    $self->foreach($cb);

    return $string;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__
