use utf8;
package Pinto::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07015 @ 2012-04-29 01:03:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yRlbDgtAuKaDHF9i1Kwqsg
#-------------------------------------------------------------------------------

# ABSTRACT: The DBIx::Class::Schema for Pinto

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

use MooseX::ClassAttribute;

#-------------------------------------------------------------------------------

has logger => (
    is      => 'rw',
    isa     => 'Pinto::Logger',
    handles => [ qw(debug notice info warning error fatal) ],
);


class_has version => (
    is        => 'ro',
    isa       => 'Int',
    default   => 1,
);

#-------------------------------------------------------------------------------

1;

__END__


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable(inline_constructor => 0);
1;
