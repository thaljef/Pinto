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

use MooseX::SetOnce;

use Pinto::Util qw(decamelize throw);

#-------------------------------------------------------------------------------

use Readonly;
Readonly::Scalar our $SCHEMA_VERSION => 1;
sub schema_version { return $SCHEMA_VERSION };

#-------------------------------------------------------------------------------

has logger => (
    is       => 'rw',
    isa      => 'Pinto::Logger',
    traits   => [ qw(SetOnce) ],
    weak_ref => 1,
);

has repo => (
    is       => 'rw',
    isa      => 'Pinto::Repository',
    traits   => [ qw(SetOnce) ],
    weak_ref => 1,
);

#-------------------------------------------------------------------------------

sub set_db_version {
    my ($self) = @_;

    # NOTE: SQLite only permits integers for the user_version.
    # The decimal portion of any float will be truncated.
    my $version = $self->schema_version;
    my $dbh     = $self->storage->dbh;

    $dbh->do("PRAGMA user_version = $version");

    return;
}

#-------------------------------------------------------------------------------

sub get_db_version {
    my ($self) = @_;

    my $dbh = $self->storage->dbh;

    my @version = $dbh->selectrow_array('PRAGMA user_version');

    return $version[0];
}

#-------------------------------------------------------------------------------

sub assert_db_version_ok {
    my ($self) = @_;

    my $schema_version = $self->schema_version;
    my $db_version     = $self->get_db_version;

    throw "Database version ($db_version) and schema version ($schema_version) do not match"
        if $db_version != $schema_version;

    return $self;
}

#-------------------------------------------------------------------------------

sub resultset_names {
    my ($class) = @_;

    my @resultset_names = sort keys %{ $class->source_registrations };

    return @resultset_names;
}

#-------------------------------------------------------------------------------

for my $rs (__PACKAGE__->resultset_names) {

    ## no critic

    no strict 'refs';
    my $rs_decameled = decamelize($rs);

    my $rs_method_name = __PACKAGE__ . "::${rs_decameled}_rs";
    *{$rs_method_name} = eval "sub { return \$_[0]->resultset('$rs') }";

    my $create_method_name = __PACKAGE__ . "::create_${rs_decameled}";
    *{$create_method_name} = eval "sub { return \$_[0]->$rs_method_name->create(\$_[1]) }";

    my $search_method_name = __PACKAGE__ . "::search_${rs_decameled}";
    *{$search_method_name} = eval "sub { return \$_[0]->$rs_method_name->search(\$_[1] || {}, \$_[2] || {}) }";

    my $find_method_name = __PACKAGE__ . "::find_${rs_decameled}";
    *{$find_method_name} = eval "sub { return \$_[0]->$rs_method_name->find(\$_[1] || {}, \$_[2] || {}) }";

    ## use critic
}

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------
1;

__END__