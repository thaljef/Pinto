# ABSTRACT: show or set stack properties

package App::Pinto::Command::props;

use strict;
use warnings;

use Pinto::Util qw(interpolate);

#-----------------------------------------------------------------------------

use base 'App::Pinto::Command';

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub opt_spec {

    return (
        [ 'format=s'             => 'Format specification (See POD for details)' ],
        [ 'properties|prop|P=s%' => 'name=value pairs of properties' ],
    );
}

#------------------------------------------------------------------------------

sub validate_args {
    my ( $self, $opts, $args ) = @_;

    $self->usage_error('Cannot specify multiple stacks')
        if @{$args} > 1;

    $opts->{format} = interpolate( $opts->{format} )
        if exists $opts->{format};

    $opts->{stack} = $args->[0]
        if $args->[0];

    return 1;
}

#------------------------------------------------------------------------------
1;

__END__

=pod

=head1 SYNOPSIS

  pinto --root=REPOSITORY_ROOT props [OPTIONS] [STACK]

=head1 DESCRIPTION

This command shows or sets stack configuration properties.  If the
C<--properties> option is given, then the properties will be set.  If
the C<--properties> option is not given, then properties will just be
shown.

=head1 COMMAND ARGUMENTS

If the C<STACK> argument is given, then the properties for that stack
will be set/shown.  If the C<STACK> argument is not given, then
properties for the default stack will be set/shown.


=head1 COMMAND OPTIONS

=over 4

=item --format=FORMAT_SPECIFICATION

Format the output using C<printf>-style placeholders.  This only
matters when showing properties.  Valid placeholders are:

  Placeholder    Meaning
  -----------------------------------------------------------------------------
  %p             Property name
  %v             Package value

=item --properties name=value

=item --prop name=value

=item -P name=value

Specifies property names and values.  You can repeat this option to
set multiple properties.  If the property with that name does not
already exist, it will be created.  Property names must be
alphanumeric plus hyphens and underscores, and will be forced to
lower case.  Setting a property to an empty string will cause it 
to be deleted.

Properties starting with the prefix C<pinto-> are reserved for
internal use, SO DO NOT CREATE OR CHANGE THEM.

=back


=head1 SUPPORTED PROPERTIES

The following properties are supported for each stack:

=over 4

=item description

A description of the stack, usually to inform users of the application
and/or environment that the stack is intended for.  For a new stack, 
defaults to "The STACK_NAME stack".  For a copied stack, defaults to 
"Copy of stack STACK_NAME".

=item target_perl_version

The version of perl that this stack is targeted at.  This is used
to determine whether a particular package is satisfied by the perl
core and therefore does not need to be added to the stack.

It must be a version string or number for an existing perl release, 
and cannot be later than the latest version specified in your
L<Module::CoreList>.  To target even newer perls, just install the 
latest version of L<Module::CoreList>.  Remember that Pinto is often
installed as a stand-alone application, so you will need to update
Pinto's copy of L<Module::CoreList> - for example:

 cpanm -L /opt/local/pinto/ Module::CoreList

=back

=cut
