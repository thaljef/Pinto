package App::Pinto::Admin::Command::list;

# ABSTRACT: list the contents of the repository

use strict;
use warnings;

use Readonly;
use List::MoreUtils qw(none);

use Pinto::Constants qw(:list);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( list ls ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    # TODO: Use the "one_of" feature of Getopt::Long::Descriptive to
    # define and validate the different types of lists.

    return (
        [ 'noinit'   => 'Do not pull/update from VCS' ],

        [ 'format=s' => 'Format specification (See POD for details)' ],

        [ 'type:s'   => "One of: ( $PINTO_LIST_TYPES_STRING )",
                        {default => $PINTO_DEFAULT_LIST_TYPE} ],

        [ 'indexed!' => 'Only list indexed packages (negatable)',
                        {default => 1} ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };
    $self->usage_error('Invalid type') if none { $opts->{type} eq $_ } @PINTO_LIST_TYPES;

    # Double-interpolate, to expand \n, \t, etc.
    $opts->{format} = eval qq{"$opts->{format}"} if $opts->{format};

    return 1;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self, $opts, $args) = @_;

    $self->pinto->new_batch( %{$opts} );
    my $list_class = 'List::' . ucfirst delete $opts->{type};
    $self->pinto->add_action($list_class, %{$opts});
    my $result = $self->pinto->run_actions();

    return $result->is_success() ? 0 : 1;

}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --path=/some/dir list [OPTIONS]

=head1 DESCRIPTION

This command lists the distributions and packages that are indexed in
your repository.  You can see all of them, only foreign ones, only
local ones, or only the local ones that conflict with a foreign one.

Note this command never changes the state of your repository.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=item  --type=(all | local | foreign | conflicts)

Specifies what type of packages and distributions to list. In all
cases, only packages and distributions that are indexed will appear.
If you have outdated distributions in your repository, they will never
appear here.  Valid types are:

=over 8

=item all

Lists all the packages and distributions.

=item local

Lists only the local packages and distributions that were added with
the C<add> command.

=item foreign

Lists only the foreign packages and distributions that were pulled in
with the C<update> command.

=item conflicts

Lists only the local distributions that conflict with a foreign
distribution.  In other words, the local and foreign distribution
contain a package with the same name.

=back

=back

=cut
