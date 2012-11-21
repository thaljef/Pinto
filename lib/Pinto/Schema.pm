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

use Readonly;
Readonly::Scalar our $SCHEMA_VERSION => 2;
sub schema_version { return $SCHEMA_VERSION };

#-------------------------------------------------------------------------------

__PACKAGE__->load_components( qw(DeploymentHandler::VersionStorage::Standard::Component) );

#-------------------------------------------------------------------------------

has logger => (
    is      => 'rw',
    isa     => 'Pinto::Logger',
    handles => [ qw(debug notice info warning error fatal) ],
);

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

#-------------------------------------------------------------------------------
1;

__END__