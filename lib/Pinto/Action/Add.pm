# ABSTRACT: Add a local distribution into the repository

package Pinto::Action::Add;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods (autoclean => 1);
use Try::Tiny;

use Pinto::Util qw(sha256 current_author_id throw);
use Pinto::Types qw(AuthorID FileList);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

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


has no_fail => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::PauseConfig Pinto::Role::Committable Pinto::Role::Puller );

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

    my (@successful, @failed);
    for my $archive ($self->archives) {

        try   {
            $self->repo->svp_begin; 
            my $dist = $self->_add($archive);
            push @successful, $dist ? $dist : ();
        }
        catch {
            throw $_ unless $self->no_fail; 
            $self->result->failed(because => $_);

            $self->repo->svp_rollback;

            $self->error("$_");
            $self->error("Archive $archive failed...continuing anyway");
            push @failed, $archive;
        }
        finally {
            my ($error) = @_;
            $self->repo->svp_release unless $error;
        };
    }

    $self->chrome->progress_done;

    return @successful;
}

#------------------------------------------------------------------------------

sub _add {
    my ($self, $archive) = @_;
    
    my $dist;
    if (my $dupe = $self->_check_for_duplicate($archive)) {
        $self->warning("$archive is the same as $dupe -- using $dupe instead");
        $dist = $dupe;
    }
    else {
        $self->info("Adding $archive to the repository");
        $dist = $self->repo->add_distribution(archive => $archive, author => $self->author);
    }

    $self->notice("Registering $dist on stack " . $self->stack);
    $self->pull(target => $dist); # Registers dist and pulls prereqs
    
    return $dist;
}

#------------------------------------------------------------------------------

sub _check_for_duplicate {
    my ($self, $archive) = @_;

    return if $self->repo->config->allow_duplicates;

    my $sha256 = sha256($archive);
    my $dupe = $self->db->schema->search_distribution({sha256 => $sha256})->first;

    return if not @dupes;
    return $dupe if $archive->basename eq $dupe->archive;

    throw "Archive $archive is the same as $dupe but with different name";
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__
