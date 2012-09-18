# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Undef Bool Str);

use Pinto::Types qw(Author Files StackName);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => Author,
    default    => sub { uc ($_[0]->pausecfg->{user} || $_[0]->username) },
    coerce     => 1,
    lazy       => 1,
);


has archives  => (
    isa       => Files,
    traits    => [ qw(Array) ],
    handles   => {archives => 'elements'},
    required  => 1,
    coerce    => 1,
);


has stack => (
    is       => 'ro',
    isa      => StackName | Undef,
    default  => undef,
    coerce   => 1,
);


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has norecurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig );

#------------------------------------------------------------------------------

sub BUILD {
    my ($self, $args) = @_;

    my @missing = grep { not -e $_ } $self->archives;
    $self->error("Archive $_ does not exist") for @missing;

    my @unreadable = grep { -e $_ and not -r $_ } $self->archives;
    $self->error("Archive $_ is not readable") for @unreadable;

    throw "Some archives are missing or unreadable"
        if @missing or @unreadable;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->archives;

    $self->repos->write_index(stack => $stack) unless $self->dryrun;

    $self->result->changed unless $self->dryrun;

    return $self->result;
}

#------------------------------------------------------------------------------

sub _get_dist_information {
    my ($self, $archive) = @_;

    my @stacks;
    my %pin;

    my $dist = $self->repos->get_distribution(author  => $self->author,
                                              archive => $archive->basename);
    if ($dist) {
        @stacks = $self->repos->get_stacks_for_distribution($dist);
 STACK:
        for my $stack (@stacks) {
            my $pkgs = $dist->packages;
            while (my $pkg = $pkgs->next) {
                if ($pkg->registration(stack => $stack)->is_pinned) {
                    $pin{$stack} = 1;
                    next STACK;
                }
            }
        }
     }
     return { stacks => \@stacks, pin => \%pin };
}

sub _execute {
    my ($self, $archive, $stack) = @_;

    $self->notice("Adding distribution archive $archive");

    my $force = $self->force;

    # With --force we keep stacks and pinning for later re-add
    my $old;
    $old = $self->_get_dist_information($archive) if $force;

    my $dist  = $self->repos->add( archive   => $archive,
                                   author    => $self->author,
                                   force     => $force,
                                 );

    my $stacks = $force ? $old->{stacks}
                        : [$stack];
    for my $s (@$stacks) {
        my $pin = $force ? $old->{pin}{$s} || $self->pin && $s eq $stack
                         : $self->pin;

        $dist->register( stack => $s );
        $dist->pin( stack => $s ) if $pin;
        $self->repos->pull_prerequisites( dist  => $dist,
                                          stack => $s
                                        ) unless $self->norecurse;
    }

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
