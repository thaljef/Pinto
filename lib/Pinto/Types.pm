package Pinto::Types;

# ABSTRACT: Moose types used within Pinto

use strict;
use warnings;

use MooseX::Types -declare => [ qw( AuthorID URI Dir File) ];
use MooseX::Types::Moose qw( Str ArrayRef );

use URI;
use Path::Class::Dir;
use Path::Class::File;
use File::HomeDir;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

subtype AuthorID,
    as Str,
    where { not m/[^A-Z0-9-]/x },
    message { "The author ($_) must be alphanumeric" };

coerce AuthorID,
    from Str,
    via  { uc $_ };

#-----------------------------------------------------------------------------

class_type URI, {class => 'URI'};

coerce URI,
    from Str,
    via { 'URI'->new($_) };

#-----------------------------------------------------------------------------

subtype Dir, as 'Path::Class::Dir';

coerce Dir,
    from Str,             via { Path::Class::Dir->new( expand_tilde($_) ) },
    from ArrayRef,        via { Path::Class::Dir->new( expand_tilde( @{$_} ) ) };

#-----------------------------------------------------------------------------

subtype File, as 'Path::Class::File';

coerce File,
    from Str,             via { Path::Class::File->new( expand_tilde($_) ) },
    from ArrayRef,        via { Path::Class::File->new( @{$_} ) };

#-----------------------------------------------------------------------------

sub expand_tilde {
    my (@paths) = @_;

    $paths[0] =~ s|\A ~ (?= \W )|File::HomeDir->my_home()|xe;

    return @paths;
}

#-----------------------------------------------------------------------------

1;

__END__
