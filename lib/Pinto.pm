# ABSTRACT: Curate a repository of Perl modules

package Pinto;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods (autoclean => 1);

use Try::Tiny;
use Class::Load;

use Pinto::Result;
use Pinto::Repository;
use Pinto::Chrome::Term;
use Pinto::Types qw(Dir);
use Pinto::Util qw(throw);

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

with qw( Pinto::Role::Plated );

#------------------------------------------------------------------------------

has root => (
    is       => 'ro',
    isa      => Dir,
    default  => $ENV{PINTO_REPOSITORY_ROOT},
    coerce   => 1,
);


has repo  => (
    is         => 'ro',
    isa        => 'Pinto::Repository',
    default    => sub { Pinto::Repository->new( root => $_[0]->root ) },
    lazy       => 1,
);

#------------------------------------------------------------------------------

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $args  = $class->$orig(@_);

    # Grrr.  Gotta avoid passing undefs to Moose
    my @chrome_attrs = qw(verbose quiet no_color);
    my %chrome_args  = map  { $_ => delete $args->{$_} } 
                       grep { exists $args->{$_}       } @chrome_attrs;

    $args->{chrome} ||= Pinto::Chrome::Term->new(%chrome_args);

    return $args;
};


#------------------------------------------------------------------------------

sub run {
    my ($self, $action_name, @action_args) = @_;

    # Divert all warnings through our chrome 
    local $SIG{__WARN__} = sub { $self->warning($_) for @_ };

    my $result = try {

        my $action = $self->create_action($action_name => @action_args);
        my $lock_type = $action->lock_type;

        $self->repo->assert_sanity_ok;
        $self->repo->assert_version_ok;
        $self->repo->lock($lock_type);

        $action->execute;
    }
    catch { 
        $self->repo->unlock;
        $self->error($_);

        Pinto::Result->new->failed(because => $_);
    }
    finally {
        $self->repo->unlock;
    };
    
    return $result; 
}

#------------------------------------------------------------------------------

sub create_action {
    my ($self, $action_name, %action_args) = @_;

    @action_args{qw(chrome repo)} = ($self->chrome, $self->repo);
    my $action_class = $self->load_class_for_action(name => $action_name);
    my $action = $action_class->new(%action_args);

    return $action;
}

#------------------------------------------------------------------------------

sub load_class_for_action {
    my ($self, %args) = @_;

    my $action_name  = ucfirst( $args{name} || throw 'Must specify an action name' );
    my $action_class = "Pinto::Action::$action_name";

    Class::Load::load_class($action_class);

    return $action_class;
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
which you can reliably build, test, and deploy your application using
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

=item * Pinto has built-in version control

When things go wrong, you can roll back any of the indexes in your
Pinto repository to a prior revision.  Also, you can view the complete
history of index changes as you add or upgrade dependencies.

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

=item * Pinto does not enforce security

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

=head1 SEE ALSO

L<pinto> to create and manage a Pinto repository.

L<pintod> to allow remote access to your Pinto repository.

L<Pinto::Manual> for general information on using Pinto.

L<Stratopan|http://stratopan.com> for hosting your Pinto repository in the cloud.

=cut
