# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Bool Str);

use Pinto::Util qw(sha256);
use Pinto::Types qw(Author FileList StackName StackObject StackDefault);
use Pinto::Exception qw(throw);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig Pinto::Role::Committable );

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => Author,
    default    => sub { uc($_[0]->pausecfg->{user} || '') || $_[0]->config->username },
    lazy       => 1,
);


has archives  => (
    isa       => FileList,
    traits    => [ qw(Array) ],
    handles   => {archives => 'elements'},
    required  => 1,
    coerce    => 1,
);


has stack => (
    is       => 'ro',
    isa      => StackName | StackDefault | StackObject,
    default  => undef,
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

    my $stack = $self->repo->open_stack($self->stack);
    $self->_add($_, $stack) for $self->archives;

    if ($self->result->made_changes and not $self->dryrun) {
        my $message = $self->edit_message(stacks => [$stack]);
        $stack->close(message => $message);
        $self->repo->write_index(stack => $stack);
    }

    return $self->result;
}

#------------------------------------------------------------------------------

sub _add {
    my ($self, $archive, $stack) = @_;

    my $dist;

    if (my $dupe = $self->_check_for_duplicate($archive)) {
        $self->warning("Archive $archive is the same as $dupe -- using $dupe instead");
        $dist = $dupe;
    }
    else {
        $self->notice("Adding distribution archive $archive");
        $dist = $self->repo->add(archive => $archive, author => $self->author);
        $self->result->changed;
    }

    my $did_register = $dist->register(stack => $stack, pin => $self->pin);
    my $did_pull = $self->norecurse ? 0 : $self->repo->pull_prerequisites(dist => $dist, stack => $stack);

    $self->result->changed if $did_pull or $did_register;
    
    return;
}

#------------------------------------------------------------------------------

sub _check_for_duplicate {
    my ($self, $archive) = @_;

    my $sha256 = sha256($archive);
    my $dupe = $self->repo->get_distribution(sha256 => $sha256);

    return if not $dupe;
    return $dupe if $archive->basename eq $dupe->archive;

    throw "Archive $archive is the same as $dupe but with different name";
}

#------------------------------------------------------------------------------

sub message_title {
    my ($self) = @_;

    my $archives  = join ', ', map {$_->basename} $self->archives;
    my $pinned    = $self->pin       ? ' and pinned'            : '';
    my $prereqs   = $self->norecurse ? ' without prerequisites' : '';

    return "Added${pinned} ${archives}$prereqs.";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
