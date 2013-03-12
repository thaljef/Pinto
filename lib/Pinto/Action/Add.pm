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


has no_recurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has no_fail => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has message_title => (
    is        => 'rw',
    isa       => Str,
    init_arg  => undef,
    default   => '',
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

    my $stack    = $self->repo->get_stack($self->stack);
    my $old_head = $stack->head;
    my $new_head = $stack->start_revision;

    my (@successful, @failed);
    for my $archive ($self->archives) {

        try   {
            $self->repo->svp_begin; 
            my $dist = $self->_add($archive, $stack);
            push @successful, $dist->to_string;
        }
        catch {
            die $_ unless $self->no_fail; 

            $self->repo->svp_rollback;

            $self->error("$_");
            $self->error("$archive failed...continuing anyway");
            push @failed, $archive->basename;
        }
        finally {
            my ($error) = @_;
            $self->repo->svp_release unless $error;
        };
    }

    return $self->result if $self->dryrun or $stack->has_not_changed;

    $self->generate_message_title('Added', @successful);
    $self->generate_message_details($stack, $old_head, $new_head);
    $stack->commit_revision(message => $self->edit_message);

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
    $self->repo->pull_prerequisites(dist => $dist, stack => $stack) unless $self->no_recurse;
    
    return $dist;
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

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
