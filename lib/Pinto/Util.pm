package Pinto::Util;

# ABSTRACT: Static utility functions for Pinto

use strict;
use warnings;

use Path::Class;
use Readonly;

use base 'Exporter';

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# TODO: Don't export!

our @EXPORT_OK = qw(directory_for_author is_source_control_file);

#-------------------------------------------------------------------------------

Readonly my %SCM_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

#-------------------------------------------------------------------------------

=func directory_for_author( @base, $author )

Given the name of an C<$author> returns the directory where the
archives for that author belong (as a L<Path::Class::Dir>).  The
optional C<@base> can be a series of L<Path::Class:Dir> or path parts
(as strings).  If C<@base> is given, it will be prepended to the
directory that is returned.

=cut

sub directory_for_author {
    my ($author) = pop;
    my @base = @_;
    $author = uc $author;
    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}

#-------------------------------------------------------------------------------
# TODO: Is this needed?

=func index_directory_for_author()

Same as C<directory_for_author()>, but returns the path as it would appear
in the F<02packages.details.txt> file.  That is, in Unix format.

=cut

sub index_directory_for_author {
    return directory_for_author(@_)->as_foreign('Unix');
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

=func native_file(@base, $file)

Given a Unix path to a file, returns the file in the native OS format
(as a L<Path::Class::File>);

=cut

sub native_file {
    my ($file) = pop;
    my (@base) = @_;
    return file(@base, split m{/}, $file);
}

#-------------------------------------------------------------------------------

1;

__END__

=head1 DESCRIPTION

This is a private module for internal use only.  There is nothing for
you to see here (yet).

=cut
