# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods (autoclean => 1);
use Try::Tiny;

use Pinto::Util qw(sha256 current_author_id);
use Pinto::Types qw(AuthorID FileList StackName StackObject StackDefault);
use Pinto::Exception qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig Pinto::Role::Committable );

#------------------------------------------------------------------------------

has author => (
    is         => 'ro',
    isa        => AuthorID,
    default    => sub { uc($_[0]->pausecfg->{user} || '') || current_author_id },
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


has nofail => (
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

    my $stack    = $self->repo->get_stack($self->stack)->start_revision;
    my @archives = $self->archives;

    while (my $archive = shift @archives) {

        try   {
            $self->repo->db->schema->storage->svp_begin; 
            $self->_add($archive, $stack);
        }
        catch {
            die $_ unless $self->nofail && @archives; 

            $self->repo->db->schema->storage->svp_rollback;

            $self->error("$_");
            $self->error("$archive failed...continuing anyway");
        }
        finally {
            my ($error) = @_;
            $self->repo->db->schema->storage->svp_release unless $error;
        };
    }

    return $self->result if $self->dryrun or $stack->has_not_changed;

    my $message = $self->edit_message(stack => $stack);
    $stack->commit_revision(message => $message);

    return $self->result->changed;
}

#------------------------------------------------------------------------------

sub _add {
    my ($self, $archive, $stack) = @_;
    
    $self->notice("Adding $archive");

    my $dist;
    if (my $dupe = $self->_check_for_duplicate($archive)) {
        $self->warning("Archive $archive is the same as $dupe -- using $dupe instead");
        $dist = $dupe;
    }
    else {
        $self->notice("Adding distribution archive $archive");
        $dist = $self->repo->add_distribution(archive => $archive, author => $self->author);
    }

    $dist->register(stack => $stack, pin => $self->pin);
    $self->repo->pull_prerequisites(dist => $dist, stack => $stack) unless $self->norecurse;
    
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
