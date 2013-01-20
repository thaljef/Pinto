CREATE TABLE repository_property (
       id              INTEGER PRIMARY KEY NOT NULL,
       key             TEXT                NOT NULL,
       key_canonical   TEXT                NOT NULL,
       value           TEXT                DEFAULT ''
);


CREATE TABLE distribution (
       id                INTEGER PRIMARY KEY NOT NULL,
       author            TEXT                NOT NULL,
       author_canonical  TEXT                NOT NULL,
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
       name                 TEXT                NOT NULL,
       name_canonical       TEXT                NOT NULL,
       is_default           BOOLEAN             NOT NULL,
       is_locked            BOOLEAN             NOT NULL 
);


CREATE TABLE prerequisite (
       id              INTEGER PRIMARY KEY NOT NULL,
       distribution    INTEGER             NOT NULL,
       package_name    TEXT                NOT NULL,
       package_version TEXT                NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id) ON DELETE CASCADE
);

/***********************************************************

Schema::Loader names the indexes for us when it generates
schema classes for us.  So I've just chosen arbitrary names

***********************************************************/

CREATE UNIQUE INDEX a ON distribution(author_canonical, archive);
CREATE UNIQUE INDEX b ON distribution(md5);
CREATE UNIQUE INDEX c ON distribution(sha256);
CREATE UNIQUE INDEX d ON package(name, distribution);
CREATE UNIQUE INDEX e ON stack(name);
CREATE UNIQUE INDEX f ON stack(name_canonical);
CREATE UNIQUE INDEX g ON repository_property(key);
CREATE UNIQUE INDEX h ON repository_property(key_canonical);
CREATE UNIQUE INDEX i ON prerequisite(distribution, package_name);
