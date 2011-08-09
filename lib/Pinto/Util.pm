package Pinto::Util;

# ABSTRACT: Static utility functions for Pinto

use strict;
use warnings;

use Path::Class;
use Readonly;

use namespace::autoclean;

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

Readonly my %SCM_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

#-------------------------------------------------------------------------------

=func author_dir( @base, $author )

Given the name of an C<$author>, returns the directory where the
distributions for that author belong (as a L<Path::Class::Dir>).  The
optional C<@base> can be a series of L<Path::Class:Dir> or path parts
(as strings).  If C<@base> is given, it will be prepended to the
directory that is returned.

=cut

sub author_dir {
    my ($author) = pop;
    my @base = @_;
    $author = uc $author;
    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}

#-------------------------------------------------------------------------------

=func is_source_control_file($path)

Given a path (which may be a file or directory), returns true if that path
is part of the internals of a source control system (e.g. git, svn, cvs).

=cut

sub is_source_control_file {
    my ($file) = @_;
    return exists $SCM_FILES{$file};
}

#-------------------------------------------------------------------------------

sub added_dist_message {
    return _dist_message(@_, 'Added');
}

#-------------------------------------------------------------------------------

sub removed_dist_message {
    return _dist_message(@_, 'Removed');
}

#-------------------------------------------------------------------------------

sub _dist_message {
    my ($dist, $action) = @_;
    my @packages = @{ $dist->packages() };
    my @items = sort map { $_->name() . ' ' . $_->version() } @packages;
    return "$action distribution $dist providing:\n    " . join "\n    ", @items;
}

#-------------------------------------------------------------------------------
1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
