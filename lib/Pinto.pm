package Pinto;

# ABSTRACT: Curate a repository of Perl modules

use Moose;
use MooseX::Types::Moose qw(Str);

use Try::Tiny;
use Class::Load;

use Pinto::Repository;

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

has repos   => (
    is         => 'ro',
    isa        => 'Pinto::Repository',
    lazy       => 1,
    default    => sub { Pinto::Repository->new( config => $_[0]->config,
                                                logger => $_[0]->logger ) },
);


has action_base_class => (
    is         => 'ro',
    isa        => Str,
    default    => 'Pinto::Action',
    init_arg   => undef,
);


#------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#------------------------------------------------------------------------------

=method run( $action_name => %action_args )

Runs the Action with the given C<$action_name>, passing the
C<%action_args> to its constructor.  Returns a L<Pinto::Result>.

=cut

sub run {
    my ($self, $action_name, %args) = @_;

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->warning(@_) };

    my $result = try {

        my $action_class = $self->action_base_class . "::$action_name";
        Class::Load::load_class($action_class);

        $self->repos->lock;
        my $guard = $self->repos->db->schema->txn_scope_guard;

        @args{qw(logger repos)} = ($self->logger, $self->repos);
        my $action = $action_class->new( %args );
        my $res = $action->execute;

        $self->repos->write_index if $res->made_changes;
        $self->info('No changes were made') if not $res->made_changes;
        $guard->commit;
        $self->repos->unlock;
        $res; # Returned from try{}
    }
    catch {

        $self->repos->unlock;
        $self->fatal($_);
    };

    return $result;
}

#------------------------------------------------------------------------------

=method add_logger( $obj )

Convenience method for installing additional endpoints for logging.
The object must be an instance of a L<Log::Dispatch::Output> subclass.

=cut

sub add_logger {
    my ($self, @args) = @_;

    $self->logger->add_output(@args);

    return $self;
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

For now, the Pinto API is private and subject to radical change
without notice.  Any module documentation you see is purely for my own
references.  In the meantime, the command line utilities mentioned in
the L</SYNOPSIS> are your public user interface.

=cut
