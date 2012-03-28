package Pinto;

# ABSTRACT: Curate your own CPAN-like repository

use Moose;

use Class::Load;

use Pinto::Config;
use Pinto::Logger;
use Pinto::Locker;
use Pinto::Batch;
use Pinto::Repository;
use Pinto::Exceptions qw(throw_fatal);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------
# Moose attributes

#------------------------------------------------------------------------------

has repos   => (
    is         => 'ro',
    isa        => 'Pinto::Repository',
    lazy_build => 1,
);


has locker  => (
    is         => 'ro',
    isa        => 'Pinto::Locker',
    init_arg   =>  undef,
    lazy_build => 1,
);


has _batch => (
    is         => 'ro',
    isa        => 'Pinto::Batch',
    writer     => '_set_batch',
    init_arg   => undef,
);


#------------------------------------------------------------------------------
# Moose roles

with qw( Pinto::Interface::Configurable
         Pinto::Interface::Loggable );

#------------------------------------------------------------------------------
# Construction

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    my $args = $class->$orig(@_);

    $args->{logger} ||= Pinto::Logger->new( $args );
    $args->{config} ||= Pinto::Config->new( $args );

    return $args;
};

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    unless (    -e $self->config->db_file()
             && -e $self->config->modules_dir()
             && -e $self->config->authors_dir() ) {

      my $root_dir = $self->config->root_dir();
      $self->fatal("Directory $root_dir does not look like a Pinto repository");
    }

    return $self;
}

#------------------------------------------------------------------------------
# Builders

sub _build_repos {
    my ($self) = @_;

    return Pinto::Repository->new( config => $self->config(),
                                   logger => $self->logger() );
}

#------------------------------------------------------------------------------

sub _build_locker {
    my ($self) = @_;

    return Pinto::Locker->new( config => $self->config(),
                               logger => $self->logger() );
}

#------------------------------------------------------------------------------
# Public methods

sub new_batch {
    my ($self, %args) = @_;

    my $batch = Pinto::Batch->new( config => $self->config(),
                                   logger => $self->logger(),
                                   repos  => $self->repos(),
                                   %args );

   $self->_set_batch( $batch );

   return $self;
}

#------------------------------------------------------------------------------

sub add_action {
    my ($self, $action_name, %args) = @_;

    my $action_class = "Pinto::Action::$action_name";

    eval { Class::Load::load_class($action_class); 1 }
        or throw_fatal "Unable to load action class $action_class: $@";

    my $action =  $action_class->new( config => $self->config(),
                                      logger => $self->logger(),
                                      repos  => $self->repos(),
                                      %args );

    $self->_batch->enqueue($action);

    return $self;
}

#------------------------------------------------------------------------------

sub run_actions {
    my ($self) = @_;

    my $batch = $self->_batch()
        or throw_fatal 'You must create a batch first';

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->whine(@_) };

    # Shit happens here!
    $self->locker->lock();
    my $r = $self->_batch->run();
    $self->locker->unlock();

    return $r;

}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

See L<pinto-admin> to create and manage a Pinto repository.

See L<pinto-server> to open remote access to a Pinto repository.

See L<pinto-remote> to interact with a remote Pinto repository.

See L<Pinto::Manual> for more information about the Pinto tools.

=head1 DESCRIPTION

Pinto is a suite of tools for creating and managing a CPAN-like
repository of Perl archives.  Pinto is inspired by L<CPAN::Mini>,
L<CPAN::Mini::Inject>, and L<MyCPAN::App::DPAN>, but adds a few
interesting features:

=over 4

=item * Pinto supports several usage patterns

With Pinto, you can create a repository to mirror all the latest
distributions from another repository.  Or you can create a "sparse
repository" with just your own private distributions.  Or you can
create a "project repository" that has all the distributions required
for a particular project.  Or you can combine any of the above in some
way.

=item * Pinto supports adding AND removing archives from the repository

Pinto gives you the power to precisely tune the contents of your
repository.  So you can be sure that your downstream clients get
exactly the stack of dependencies that you want them to have.

=item * Pinto can be integrated with your version control system

Pinto can automatically commit to your version control system whenever
the contents of the repository changes.  This gives you repeatable and
identifiable snapshots of your dependencies, and a mechanism for
rollback when things go wrong.

=item * Pinto makes it easier to build several local repositories

Creating new Pinto repositories is easy, and each has its own
configuration.  So you can have different repositories for each
department, or each project, or each version of perl, or each
customer, or whatever you want.

=item * Pinto can pull archives from multiple remote repositories

Pinto can mirror or import distributions from multiple sources, so you
can create private (or public) networks of repositories that enable
separate teams or individuals to collaborate and share distributions.

=item * Pinto supports team development

Pinto is suitable for small to medium-sized development teams, where
several developers might contribute new distributions at the same
time.  Pinto ensures that concurrent users don't step on each other.

=item * Pinto has a robust command line interface.

The L<pinto-admin> and L<pinto-remote> command line tools have options
to control every aspect of your Pinto repository.  They are well
documented and behave in the customary UNIX fashion.

=item * Pinto can be extended.

You can extend Pinto by creating L<Pinto::Action> subclasses to
perform new operations on your repository, such as extracting
documentation from a distribution, or grepping the source code of
several distributions.

=back

In some ways, Pinto is also similar to L<PAUSE|http://pause.perl.org>.
Both are capable of accepting distributions and constructing a
directory structure and index that toolchain clients understand.  But
there are some important differences:

=over

=item * Pinto does not promise to index exactly like PAUSE does

Over the years, PAUSE has evolved complicated heuristics for dealing
with all the different ways that Perl code is written and
distributions are organized.  Pinto is much less sophisticated, and
only aspires to produce an index that is "good enough" for most
applications.

=item * Pinto does not understand author permissions

PAUSE has a system of assigning ownership and co-maintenance
permission to individuals or groups.  But Pinto only has a basic
"first-come" system of ownership.  The ownership controls are only
advisory and can easily be bypassed (see next item below).


=item * Pinto is not secure

PAUSE requires authors to authenticate themselves before they can
upload or remove distributions.  However, Pinto does not authenticate
and permits users masquerade as anybody they want to be.  This is
actually intentional and designed to encourage collaboration among
developers.

=back

=head1 BUT WHERE IS THE API?

For now, the Pinto API is private, undocumented, and subject to
radical change without notice.  In the meantime, the command line
utilities mentioned in the L</SYNOPSIS> are your public interface.

=cut
