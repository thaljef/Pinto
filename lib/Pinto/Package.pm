package Pinto::Package;

# ABSTRACT: Represents a single record in the 02packages.details.txt file

use strict;
use warnings;

use Path::Class qw();

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

sub new {
    my ($class, %args) = @_;
    $args{version} ||= 'undef';
    $args{author} ||=  Path::Class::file( $args{file} )->dir()->dir_list(2, 1);
    return bless \%args, $class;
}

#------------------------------------------------------------------------------
# Accessors

sub name        { return $_[0]->{name} }
sub file        { return $_[0]->{file} }
sub version     { return $_[0]->{version} }
sub author      { return $_[0]->{author} }
sub native_file { return Path::Class::file( $_[0]->{file} ) }

#------------------------------------------------------------------------------
# Methods

sub to_string {
    my ($self) = @_;
    my $fw = 38 - length $self->version();
    $fw = length $self->name() if $fw < length $self->name();
    return sprintf "%-${fw}s %s  %s", $self->{name}, $self->{version}, $self->{file};
}

#------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
