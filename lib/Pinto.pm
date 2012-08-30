# ABSTRACT: Curate a repository of Perl modules

package Pinto;

use Moose;

use Try::Tiny;

use Pinto::Repository;
use Pinto::ActionLoader;

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


has action_loader => (
    is        => 'ro',
    isa       => 'Pinto::ActionLoader',
    lazy      => 1,
    default   => sub { Pinto::ActionLoader->new( config => $_[0]->config,
                                                 logger => $_[0]->logger ) },
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
    my ($self, $action_name, %action_args) = @_;

    # Divert any warnings to our logger
    local $SIG{__WARN__} = sub { $self->warning(@_) };

    $self->repos->lock_exclusive;
    $self->repos->check_schema_version;
    $self->repos->txn_begin;

    my $action_class = $self->action_loader->load_action(name => $action_name);

    my $result = try {

        @action_args{qw(logger repos)} = ($self->logger, $self->repos);
        my $action = $action_class->new( %action_args );
        my $res = $action->execute;

        # TODO: Consider using a role to indicate whether an
        # Action can do a dryrun (e.g. Pinto::Role::Dryrunable)

        if ($action->can('dryrun') && $action->dryrun) {
            $self->notice('Dryrun -- rolling back');
            $self->repos->txn_rollback;
            $self->repos->clean_files;
        }
        elsif ( not $res->made_changes ) {
            $self->notice('No changes were made');
            $self->repos->txn_rollback;
        }
        else {
            $self->repos->txn_commit;
        }

        $res; # returned from try{}
    }
    catch {
        $self->repos->txn_rollback;
        $self->repos->unlock;
        die $_;        ## no critic qw(Carping)

    };

    $self->repos->unlock;
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

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------

1;

__END__

=pod

=head1 SYNOPSIS

See L<pinto> to create and manage a Pinto repository.

See L<pintod> to allow remote access to your Pinto repository.

See L<Pinto::Manual> for more information about the Pinto tools.

=head1 DESCRIPTION

Pinto is a suite of tools and libraries for creating and managing a
custom CPAN-like repository of Perl modules.  The purpose of such a
repository is to provide a stable, curated stack of dependencies from
which you can reliably build, test, and delploy your application using
the standard Perl tool chain. Pinto supports various operations for
gathering and managing distribution dependencies within the
repository, so that you can control precisely which dependencies go
into your application.

=head1 FEATURES

Pinto is inspired by L<Carton>, L<CPAN::Mini::Inject>, and
L<MyCPAN::App::DPAN>, but adds a few interesting features:

=over 4

=item * Pinto supports mutiple indexes

A Pinto repository can have multiple indexes.  Each index corresponds
to a "stack" of dependencies that you can control.  So you can have
one stack for development, one for production, one for feature-xyz,
and so on.  You can also branch and merge stacks to experiment with
new dependencies or upgrades.

=item * Pinto helps manage incompatibilies between dependencies

Sometimes, you discover that a new version of a dependency is
incompatible with your application.  Pinto allows you to "pin" a
dependency to a stack, which prevents it from being accidentally
upgraded (either directly or via some other dependency).

=item * Pinto can pull archives from multiple remote repositories

Pinto can pull dependencies from multiple sources, so you can create
private (or public) networks of repositories that enable separate
teams or individuals to collaborate and share Perl modules.

=item * Pinto supports team development

Pinto is suitable for small to medium-sized development teams and
supports concurrent users.  Pinto also has a web service interface
(via L<pintod>), so remote developers can use a centrally hosted
repository.

=item * Pinto has a robust command line interface.

The L<pinto> utility has commands and options to control every aspect
of your Pinto repository.  They are well documented and behave in the
customary UNIX fashion.

=item * Pinto can be extended.

You can extend Pinto by creating L<Pinto::Action> subclasses to
perform new operations on your repository, such as extracting
documentation from a distribution, or grepping the source code of
several distributions.

=back

=head1 Pinto vs PAUSE

In some ways, Pinto is similar to L<PAUSE|http://pause.perl.org>.
Both are capable of accepting distributions and constructing a
directory structure and index that Perl installers understand.  But
there are some important differences:

=over

=item * Pinto does not promise to index exactly like PAUSE does

Over the years, PAUSE has evolved complicated heuristics for dealing
with all the different ways that Perl code is written and packaged.
Pinto is much less sophisticated, and only aspires to produce an index
that is "good enough" for most situations.

=item * Pinto does not understand author permissions

PAUSE has a system of assigning ownership and co-maintenance
permission of modules to specific people.  Pinto does not have any
such permission system.  All activity is logged so you can identify
the culprit, but Pinto expects you to be accountable for your actions.

=item * Pinto is not (always) secure

PAUSE requires authors to authenticate themselves before they can
upload or remove modules.  Pinto does not require authentication, so
any user with sufficient file permission can potentialy change the
repository.  However L<pintod> does suport HTTP authentication, which
gives you some control over access to a remote repository.

=back

=head1 BUT WHERE IS THE API?

For now, the Pinto API is private and subject to radical change
without notice.  Any API documentation you see is purely for my own
references.  In the meantime, the command line utilities mentioned in
the L</SYNOPSIS> are your public user interface.

=cut
