# ABSTRACT: Interface to the Pinto database

package Pinto::Database;

use Moose;
use MooseX::StrictConstructor;
use MooseX::ClassAttribute;
use MooseX::MarkAsMethods (autoclean => 1);
use MooseX::Types::Moose qw(Str);

use Path::Class qw(file);

use Pinto::Schema;
use Pinto::Types qw(File);
use Pinto::Util qw(debug throw);

#-------------------------------------------------------------------------------

# VERSION

#-------------------------------------------------------------------------------

has repo => (
   is         => 'ro',
   isa        => 'Pinto::Repository',
   weak_ref   => 1,
   required   => 1,
);


has schema => (
   is         => 'ro',
   isa        => 'Pinto::Schema',
   builder    => '_build_schema',
   init_arg   => undef,
   lazy       => 1,
);


class_has ddl => (
   is         => 'ro',
   isa        => Str,
   init_arg   => undef,
   default    => do { local $/ = undef; <DATA> },
   lazy       => 1,
);

#-------------------------------------------------------------------------------

sub _build_schema {
    my ($self) = @_;

    my $schema = Pinto::Schema->new;

    my $db_file = $self->repo->config->db_file;
    my $dsn     = "dbi:SQLite:$db_file";
    my $xtra    = {on_connect_call => 'use_foreign_keys'};
    my @args    = ($dsn, undef, undef, $xtra);

    my $connected = $schema->connect(@args);

    # Inject attributes thru back door
    $connected->repo($self->repo);

    # Tune sqlite (taken from monotone)...
    my $dbh = $connected->storage->dbh;
    $dbh->do('PRAGMA page_size    = 8192');
    $dbh->do('PRAGMA cache_size   = 4000');

    # These may be unhelpful or unwise...
    #$dbh->do('PRAGMA temp_store   = MEMORY');
    #$dbh->do('PRAGMA journal_mode = WAL');
    #$dbh->do('PRAGMA synchronous  = OFF');

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

    my $db_dir = $self->repo->config->db_dir;
    debug("Makding db directory at $db_dir");
    $db_dir->mkpath;

    my $guard = $self->schema->storage->txn_scope_guard;
    $self->create_database_schema;
    $self->create_root_revision;
    $guard->commit;

    return $self;
}

#-------------------------------------------------------------------------------

sub create_database_schema {
    my ($self) = @_;

    debug("Creating database schema");
    
    my $dbh = $self->schema->storage->dbh;
    $dbh->do("$_;") for split /;/, $self->ddl;

    return $self;
}

#-------------------------------------------------------------------------------

sub create_root_revision {
    my ($self) = @_;

    my $attrs = { uuid         => $self->root_revision_uuid, 
                  message      => 'root commit', 
                  is_committed => 1 };

    debug("Creating root revision");

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

__DATA__

CREATE TABLE distribution (
       id              INTEGER PRIMARY KEY NOT NULL,
       author          TEXT                NOT NULL        COLLATE NOCASE,
       archive         TEXT                NOT NULL,
       source          TEXT                NOT NULL,
       mtime           INTEGER             NOT NULL,
       sha256          TEXT                NOT NULL,
       md5             TEXT                NOT NULL,
       metadata        TEXT                NOT NULL,

       UNIQUE(author, archive)
);


CREATE TABLE package (
       id              INTEGER PRIMARY KEY NOT NULL,
       name            TEXT                NOT NULL,
       version         TEXT                NOT NULL,
       file            TEXT                DEFAULT NULL,
       sha256          TEXT                DEFAULT NULL,
       distribution    INTEGER             NOT NULL        REFERENCES distribution(id) ON DELETE CASCADE,

       UNIQUE(name, distribution)
);


CREATE TABLE stack (
       id              INTEGER PRIMARY KEY NOT NULL,
       name            TEXT                NOT NULL        UNIQUE COLLATE NOCASE,
       is_default      BOOLEAN             NOT NULL,
       is_locked       BOOLEAN             NOT NULL,
       properties      TEXT                NOT NULL,
       head            INTEGER             NOT NULL        REFERENCES revision(id)     ON DELETE RESTRICT
);


CREATE TABLE registration (
       id              INTEGER PRIMARY KEY NOT NULL,
       revision        INTEGER             NOT NULL        REFERENCES revision(id)     ON DELETE CASCADE,
       package_name    TEXT                NOT NULL,
       package         INTEGER             NOT NULL        REFERENCES package(id)      ON DELETE CASCADE,
       distribution    INTEGER             NOT NULL        REFERENCES distribution(id) ON DELETE CASCADE,
       is_pinned       BOOLEAN             NOT NULL,

       UNIQUE(revision, package_name)
);


CREATE TABLE revision (
       id              INTEGER PRIMARY KEY NOT NULL,
       uuid            TEXT                NOT NULL        UNIQUE,
       message         TEXT                NOT NULL,
       username        TEXT                NOT NULL,
       utc_time        INTEGER             NOT NULL,
       time_offset     INTEGER             NOT NULL,
       is_committed    BOOLEAN             NOT NULL,
       has_changes     BOOLEAN             NOT NULL
);


CREATE TABLE ancestry (
       id              INTEGER PRIMARY KEY NOT NULL,
       parent          INTEGER             NOT NULL        REFERENCES revision(id)     ON DELETE CASCADE,
       child           INTEGER             NOT NULL        REFERENCES revision(id)     ON DELETE CASCADE
);


CREATE TABLE prerequisite (
       id              INTEGER PRIMARY KEY NOT NULL,
       phase           TEXT                NOT NULL,
       distribution    INTEGER             NOT NULL        REFERENCES distribution(id) ON DELETE CASCADE,
       package_name    TEXT                NOT NULL,
       package_version TEXT                NOT NULL,

       UNIQUE(distribution, phase, package_name)
);

CREATE INDEX idx_ancestry_parent           ON ancestry(parent);
CREATE INDEX idx_ancestry_child            ON ancestry(child);
CREATE INDEX idx_package_sha256            ON package(sha256);
CREATE INDEX idx_distribution_sha256       ON distribution(sha256);

