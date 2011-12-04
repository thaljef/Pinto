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

Specifies how the output should be formatted using C<printf>-like
placeholders.  The following placeholders are allowed:

  Placeholder    Meaning
  -----------------------------------------------------------------------
  n              Package name
  N              Package name-version
  v              Package version
  V              Package numeric version
  m              Package maturity:      [D] = developer  [R] = release
  x              Index status:          [*] = latest     [-] = ineligible
  p              Logical distribution path
  P              Native distribtuion path (relative to the repository)
  s              Distribution source:   [L] = local      [F] = foreign
  S              Distribution source URL
  d              Distribution name
  D              Distribution name-version
  w              Distribution version
  W              Distribution numeric version
  u              Distribution url
  -----------------------------------------------------------------------

The default format is: C<%x%m%s %n %v %p\n>.  See L<String::Format>
for additional information on the formatting capabilities, such as
specifying field width, alignment, and padding.

=item --noinit

Prevents L<Pinto> from pulling/updating the repository from the VCS
before the operation.  This is only relevant if you are using a
VCS-based storage mechanism.  This can speed up operations
considerably, but should only be used if you *know* that your working
copy is up-to-date and you are going to be the only actor touching the
Pinto repository within the VCS.

=back

=cut
