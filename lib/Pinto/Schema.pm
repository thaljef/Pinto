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

use Pinto::Exception qw(throw);
use Pinto::Util qw(decamelize);

#-------------------------------------------------------------------------------

use Readonly;
Readonly::Scalar our $SCHEMA_VERSION => 1;
sub schema_version { return $SCHEMA_VERSION };

#-------------------------------------------------------------------------------

with qw( Pinto::Role::Configurable
	     Pinto::Role::Loggable );

#-------------------------------------------------------------------------------

sub BUILDARGS { 
	my $class = shift;
	return scalar @_ == 1 ? { %{ $_[0] } } : { @_ };
}

#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->next::method;
    $self->set_version;
    $self->set_root_kommit;

    return $self;
}

#-------------------------------------------------------------------------------

sub set_version {
    my ($self) = @_;

    # NOTE: SQLite only permits integers for the user_version.
    # The decimal portion of any float will be truncated.
    my $version = $self->schema_version;
    my $dbh     = $self->storage->dbh;

    $dbh->do("PRAGMA user_version = $version");

    return;
}

#-------------------------------------------------------------------------------

sub get_version {
    my ($self) = @_;

    my $dbh = $self->storage->dbh;

    my @version = $dbh->selectrow_array('PRAGMA user_version');

    return $version[0];
}

#-------------------------------------------------------------------------------

sub set_root_kommit {
    my ($self) = @_;

    my $attrs = { sha256   => $self->root_kommit_sha, 
    	          username => 'pinto', 
    	          message  => 'root kommit' };

    return $self->create_kommit($attrs);   
}

#-------------------------------------------------------------------------------

sub get_root_kommit {
    my ($self) = @_;

    my $where = {sha256 => $self->root_kommit_sha};
    my $attrs = {key => 'sha256_unique'};

    my $kommit = $self->find_kommit($where, $attrs)
        or throw "PANIC: No root kommit was found";

    return $kommit;
}

#-------------------------------------------------------------------------------

sub root_kommit_sha { return '0' x 32 }

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