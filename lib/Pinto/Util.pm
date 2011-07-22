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

sub directory_for_author {
    my ($author) = pop;
    my @base = @_;
    $author = uc $author;
    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}

#-------------------------------------------------------------------------------
# TODO: Is this needed?

sub index_directory_for_author {
    return directory_for_author(@_)->as_foreign('Unix');
}

#-------------------------------------------------------------------------------

sub is_source_control_file {
    my ($file) = @_;
    return exists $SCM_FILES{$file};
}

#-------------------------------------------------------------------------------

sub native_file {
    my ($file) = pop @_;
    my (@base) = @_;
    return file(@base, split m{/}, $file);
}

#-------------------------------------------------------------------------------

1;

__END__

