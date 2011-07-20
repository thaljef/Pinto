package Pinto::Util;

use strict;
use warnings;

use Path::Class;

use base 'Exporter';

#--------------------------------------------------------------------------------

our @EXPORT_OK = qw(directory_for_author);

#--------------------------------------------------------------------------------

sub directory_for_author {
    my ($author, @base) = @_;
    $author = uc $author;
    return dir(@base, substr($author, 0, 1), substr($author, 0, 2), $author);
}
