# ABSTRACT: Compute difference between two sets of registrations

package Pinto::Difference;

use Moose;
use MooseX::Types::Moose qw(ArrayRef);
use MooseX::MarkAsMethods (autoclean => 1);

use Pinto::Util qw(itis);

use overload ( q{""} => 'to_string' );

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has left => (
    is       => 'ro',
    isa      => 'Pinto::Schema::ResultSet::Registration',
    required => 1,
);


has right => (
    is       => 'ro',
    isa      => 'Pinto::Schema::ResultSet::Registration',
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
        my $arg = $args->{$side};
        if (itis($arg, 'Pinto::Schema::Result::Revision')) {
            $args->{$side} = $arg->registrations->with_package->with_distribution;
        }
        elsif (itis($arg, 'Pinto::Schema::Result::Stack')) {
            $args->{$side} = $arg->head->registrations->with_package->with_distribution;
        }
    }

    return $args;
};

#------------------------------------------------------------------------------

sub _build_diffs {
    my ($self) = @_;

    my $cb = sub {
        my ($self) = @_;
        my @fields = qw(distribution package is_pinned);
        return join '|', map {$self->get_column($_)} @fields;
    };

    # Compute left and right sets as hashes
    my %left  = $self->left->as_hash($cb);
    my %right = $self->right->as_hash($cb);

    # Compute differences between left and right sets
    my @added   = @right{ grep { not exists $left{$_}  } keys %right };
    my @deleted = @left{  grep { not exists $right{$_} } keys %left  };

    # Construct an ordered list of differences
    my @adds = map { ['+' => $_] } @added;
    my @dels = map { ['-' => $_] } @deleted;

    # Strictly speaking, the registrations are an unordered list.  But
    # the diff is more readable if we group related registrations together.
    # So we sort them by distribution and package name.

    my @diffs = sort {    
        ($a->[1]->distribution  cmp $b->[1]->distribution) || 
        ($a->[1]->package_name  cmp $b->[1]->package_name)        
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
