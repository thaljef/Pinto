# ABSTRACT: Something pulls packages to a stack

package Pinto::Role::Puller;

use Moose::Role;
use MooseX::Types::Moose qw(ArrayRef Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use List::MoreUtils qw(any);

use Pinto::Util qw(throw whine);

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

with qw( Pinto::Role::Plated );

#-----------------------------------------------------------------------------

has recurse => (
    is      => 'ro',
    isa     => Bool,
    default => sub { shift->stack->repo->config->recurse },
    lazy    => 1,
);

has cascade => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has pin => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has skip_missing_prerequisite => (
    is        => 'ro',
    isa       => ArrayRef[Str],
    default   => sub { [] },
);

has skip_all_missing_prerequisites => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

has with_development_prerequisites => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#-----------------------------------------------------------------------------

# We should require a stack() attribute here, but Moose can't properly
# resolve attributes that are composed from other roles.  For more info
# see https://rt.cpan.org/Public/Bug/Display.html?id=46347

# requires qw(stack);

#-----------------------------------------------------------------------------

sub pull {
    my ( $self, %args ) = @_;

    my $target = $args{target};
    my $stack  = $self->stack;
    my $dist;

    if ( $target->isa('Pinto::Schema::Result::Distribution') ) {
        $dist = $target;
    }
    elsif ( $target->isa('Pinto::Target::Distribution') ) {
        $dist = $self->find( target => $target );
    }
    elsif ( $target->isa('Pinto::Target::Package') ) {

        my $tpv = $stack->target_perl_version;
        if ( $target->is_core( in => $tpv ) ) {
            $self->warning("Skipping $target: included in perl $tpv core");
            return;
        }

        $dist = $self->find( target => $target );
    }
    else {
        throw "Illeagal arguments";
    }

    $dist->register( stack => $stack, pin => $self->pin );
    $self->do_recursion( start => $dist ) if $self->recurse;

    return $dist;
}

#-----------------------------------------------------------------------------

sub find {
    my ( $self, %args ) = @_;

    my $target = $args{target};
    my $stack  = $self->stack;

    my $dist;
    my $msg;

    if ( $dist = $stack->get_distribution( target => $target ) ) {
        $msg = "Found $target on stack $stack in $dist";
    }
    elsif ( $dist = $stack->repo->get_distribution( target => $target ) ) {
        $msg = "Found $target in $dist";
    }
    elsif ( $dist = $stack->repo->ups_distribution( target => $target, cascade => $self->cascade ) ) {
        $msg = "Found $target in " . $dist->source;
    }
    elsif ( $self->should_skip_missing_prerequisite($target) ) {
        whine "Cannot find $target anywhere.  Skipping it";
        return;
    }
    else {
        throw "Cannot find $target anywhere";
    }

    $self->chrome->show_progress;
    $self->info($msg) if defined $msg;

    return $dist;
}

#-----------------------------------------------------------------------------

sub do_recursion {
    my ( $self, %args ) = @_;

    my $dist  = $args{start};
    my $stack = $self->stack;

    my %last_seen;
    my $cb = sub {
        my ($prereq) = @_;

        my $target   = $prereq->as_target;
        my $pkg_name = $target->name;
        my $pkg_vers = $target->version;

        # version sees undef and 0 as equal, so must also check definedness
        # when deciding if we've seen this version (or newer) of the package
        return if defined( $last_seen{$pkg_name} ) && $target->is_satisfied_by( $last_seen{$pkg_name} );

        return if not my $dist = $self->find( target => $target );

        $dist->register( stack => $stack );

        # Record the most recent version of the packages that has
        # been registered, so we don't need to find it again.
        $last_seen{$_->name} = $_->version for $dist->packages;

        return $dist;
    };

    # Exclude perl itself, and prereqs that are satisfied by the core
    my @filters = ( sub { $_[0]->is_perl || $_[0]->is_core( in => $stack->target_perl_version ) } );

    # Exlucde develop-time dependencies, unless asked not to
    push @filters, sub { $_[0]->phase eq 'develop' }
        unless $self->with_development_prerequisites;

    require Pinto::PrerequisiteWalker;
    my $walker = Pinto::PrerequisiteWalker->new( start => $dist, callback => $cb, filters => \@filters );

    $self->notice("Descending into prerequisites for $dist");

    while ( $walker->next ) { };    # Just want the callback side effects

    return $self;
}

#-----------------------------------------------------------------------------

sub should_skip_missing_prerequisite {
    my ($self, $target) = @_;

    return 1 if $self->skip_all_missing_prerequisites;
    return 0 unless my @skips = @{ $self->skip_missing_prerequisite };
    return 1 if any { $target->name eq $_ } @skips;
    return 0;
}

#-----------------------------------------------------------------------------
1;

__END__
