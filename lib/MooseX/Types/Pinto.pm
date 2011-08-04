package MooseX::Types::Pinto;

# ABSTRACT: Moose types used within Pinto

use strict;
use warnings;

use MooseX::Types -declare => [ qw( AuthorID URI Dir File) ];
use MooseX::Types::Moose qw( Str );

use URI;
use Path::Class::Dir;
use Path::Class::File;

use namespace::autoclean;

#-----------------------------------------------------------------------------

# VERSION

#-----------------------------------------------------------------------------

subtype AuthorID,
    as Str,
    where { not /[a-z\W]/ },
    message { "The author ($_) must be only capital letters" };

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
    from Str,
    via { Path::Class::Dir->new($_) };

#-----------------------------------------------------------------------------

subtype File, as 'Path::Class::File';

coerce File,
    from Str,
    via { Path::Class::File->new($_) };

#-----------------------------------------------------------------------------

1;

__END__
