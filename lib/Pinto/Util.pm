package Pinto::Util;

use strict;
use warnings;

use Path::Class;
use Readonly;

use base 'Exporter';

#--------------------------------------------------------------------------------

our @EXPORT_OK = qw(directory_for_author is_source_control_file);

#--------------------------------------------------------------------------------

Readonly my %SCM_FILES => (map {$_ => 1} qw(.svn .git .gitignore CVS));

#--------------------------------------------------------------------------------

sub directory_for_author {
    my ($author, @base) = @_;
    $author = uc $author;
    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}


#--------------------------------------------------------------------------------

sub is_source_control_file {
    my ($file) = @_;
    return exists $SCM_FILES{$file};
}
