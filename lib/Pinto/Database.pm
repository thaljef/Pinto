# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;
use MooseX::MarkAsMethods (autoclean => 1);

use Path::Class qw(file);
use File::ShareDir qw(dist_file);

use Pinto::Schema;
use Pinto::Types qw(File);
use Pinto::Exception qw(throw);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------
# Attributes

has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   builder    => '_build_schema',
   init_arg   => undef,
   lazy       => 1,
);


has repo => (
   is         => 'ro',
   isa        => 'Pinto::Repository',
   weak_ref   => 1,
   required   => 1,
);


has ddl_file => (
   is         => 'ro',
   isa        => File,
   init_arg   => undef,
   default    => sub { file( dist_file( qw(Pinto pinto.ddl) ) ) },
   lazy       => 1,
);

#-------------------------------------------------------------------------------
# Roles

with qw( Pinto::Role::Configurable
         Pinto::Role::Loggable );

#-------------------------------------------------------------------------------
# Builders

sub _build_schema {
    my ($self) = @_;

    my $schema = Pinto::Schema->new;

    my $db_file = $self->config->db_file;
    my $dsn     = "dbi:SQLite:$db_file";
    my $xtra    = {on_connect_call => 'use_foreign_keys'};
    my @args    = ($dsn, undef, undef, $xtra);

    my $connected = $schema->connect(@args);

    # Inject attributes thru back door
    $connected->logger($self->logger);
    $connected->repo($self->repo);

    # Tune sqlite (taken from monotone)...
    my $dbh = $connected->storage->dbh;
    $dbh->do('PRAGMA page_size    = 8192');
    $dbh->do('PRAGMA cache_size   = 4000');

    # These may be unhelpful or unwise...
    #$dbh->do('PRAGMA temp_store   = MEMORY');
    #$dbh->do('PRAGMA journal_mode = WAL');
    $dbh->do('PRAGMA synchronous  = OFF');

    return $connected;
}

#-------------------------------------------------------------------------------
# NB: We used to just let DBIx::Class generate the DDL from its own schema, but 
# SQL::Translator does not support the COLLATE feature of SQLite.  So now, we
# ship Pinto with a real copy of the DDL, and feed it into the database when
# the repository is initialized.
#
# Personally, I kinda prefer having a raw DDL file, rather than generating it 
# because then I know *exactly* what the database schema will be, and we are 
# no longer exposed to bugs that might exist in SQL::Translator.  We don't need
# to deploy to different RDBMSes, so we don't really need SQL::Translator to 
# help with that anyway.
#
# DBD::SQLite can only process one statement at a time, so we have to parse
# the file and "do" each statement separately.  Splitting on semicolons is
# primitive, but effective (as long as semicolons are only used in statement
# terminators).
#-------------------------------------------------------------------------------

sub deploy {
    my ($self) = @_;

    $self->config->db_dir->mkpath;

    my $dbh = $self->schema->storage->dbh;
    my $ddl = $self->ddl_file->slurp;

    my $guard = $self->schema->storage->txn_scope_guard;
    $dbh->do("$_;") for split /;/, $ddl;
    $self->create_root_revision;
    $guard->commit;

    return $self;
}

#-------------------------------------------------------------------------------

sub create_root_revision {
    my ($self) = @_;

    my $attrs = { uuid         => $self->root_revision_uuid, 
                  message      => 'root commit', 
                  is_committed => 1 };

    return $self->schema->create_revision($attrs);   
}

#-------------------------------------------------------------------------------

sub get_root_revision {
    my ($self) = @_;

    my $where = {uuid => $self->root_revision_uuid};
    my $attrs = {key => 'uuid_unique'};

    my $revision = $self->schema->find_revision($where, $attrs)
        or throw "PANIC: No root revision was found";

    return $revision;
}

#-------------------------------------------------------------------------------

sub root_revision_uuid { return '00000000-0000-0000-0000-000000000000' }

#-------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-------------------------------------------------------------------------------

1;

__END__
