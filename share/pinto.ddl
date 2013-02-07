CREATE TABLE distribution (
       id                INTEGER PRIMARY KEY NOT NULL,
       author            TEXT                NOT NULL COLLATE NOCASE,
       archive           TEXT                NOT NULL,
       source            TEXT                NOT NULL,
       mtime             INTEGER             NOT NULL,
       sha256            TEXT                NOT NULL,
       md5               TEXT                NOT NULL 
);


CREATE TABLE package (
       id            INTEGER PRIMARY KEY NOT NULL,
       name          TEXT                NOT NULL,
       version       TEXT                NOT NULL,
       file          TEXT                DEFAULT NULL,
       sha256        TEXT                DEFAULT NULL,
       distribution  INTEGER             NOT NULL,

       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE
);

CREATE TABLE stack (
       id                   INTEGER PRIMARY KEY NOT NULL,
       name                 TEXT                NOT NULL COLLATE NOCASE,
       is_default           BOOLEAN             NOT NULL,
       is_locked            BOOLEAN             NOT NULL,
       last_commit_id       TEXT                DEFAUlT ''
);


CREATE TABLE prerequisite (
       id              INTEGER PRIMARY KEY NOT NULL,
       distribution    INTEGER             NOT NULL,
       package_name    TEXT                NOT NULL,
       package_version TEXT                NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id) ON DELETE CASCADE
);


/*****************************************************************************
* These index names must match those that are created by DBIC::Schema::Loader.
* If you create or change an index, make sure the name generated for the Schema
* classes is added or changed here as well.
*****************************************************************************/

CREATE UNIQUE INDEX author_archive_unqiue            ON distribution(author, archive);
CREATE UNIQUE INDEX md5_unique                       ON distribution(md5);
CREATE UNIQUE INDEX sha256_unique                    ON distribution(sha256);
CREATE UNIQUE INDEX name_distribution_unique         ON package(name, distribution);
CREATE UNIQUE INDEX name_unique                      ON stack(name);
CREATE UNIQUE INDEX distribution_package_name_unique ON prerequisite(distribution, package_name);
