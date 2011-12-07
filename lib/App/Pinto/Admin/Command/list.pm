package App::Pinto::Admin::Command::list;

# ABSTRACT: list the contents of the repository

use strict;
use warnings;

use Readonly;
use List::MoreUtils qw(none);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Admin::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub command_names { return qw( list ls ) }

#------------------------------------------------------------------------------

sub opt_spec {
    my ($self, $app) = @_;

    return (

        [ 'noinit'   => 'Do not pull/update from VCS' ],
        [ 'format=s' => 'Format specification (See POD for details)' ],

    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ($self, $opts, $args) = @_;

    $self->usage_error('Arguments are not allowed') if @{ $args };

    ## no critic qw(StringyEval)
    ## Double-interpolate, to expand \n, \t, etc.
    $opts->{format} = eval qq{"$opts->{format}"} if $opts->{format};

    return 1;
}

#------------------------------------------------------------------------------

1;

__END__

=head1 SYNOPSIS

  pinto-admin --path=/some/dir list [OPTIONS]

=head1 DESCRIPTION

This command lists the distributions and packages that are indexed in
your repository.  You can format the output to see the specific bits
of information that you want.

Note this command never changes the state of your repository.

=head1 COMMAND ARGUMENTS

None.

=head1 COMMAND OPTIONS

=over 4

=item --format=FORMAT_SPECIFICATION

Sets the format of the output using C<printf>-style placeholders.
Valid placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %n             Package name
  %N             Package name-version
  %v             Package version
  %x             Index status:                   (@) = is latest
  %y             Pin status:                     (+) = is pinned
  %m             Distribution maturity:          (d) = developer, (r) = release
  %p             Distribution index path [1]
  %P             Distribution physical path [2]
  %s             Distribution origin:            (l) = local, (f) = foreign
  %S             Distribution source repository
  %a             Distribution author
  %d             Distribution name
  %D             Distribution name-version
  %w             Distribution version
  %u             Distribution url
  %%             A literal '%'


  [1]: The index path is always a Unix-style path fragment, as it
       appears in the 02packages.details.txt index file.

  [2]: The physical path is always in the native style for this OS,
       and is relative to the root directory of the repository.

You can also specify the minimum field widths and left or right
justification, using the usual notation.  For example, this is what
the default format looks like.

  %x%m%s %-38n %v %p\n

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=back

=cut
