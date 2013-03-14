CREATE TABLE distribution (
       id              INTEGER PRIMARY KEY NOT NULL,
       author          TEXT                NOT NULL        COLLATE NOCASE,
       archive         TEXT                NOT NULL,
       source          TEXT                NOT NULL,
       mtime           INTEGER             NOT NULL,
       sha256          TEXT                NOT NULL        UNIQUE,
       md5             TEXT                NOT NULL        UNIQUE,

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
       distribution    INTEGER             NOT NULL        REFERENCES distribution(id) ON DELETE CASCADE,
       package_name    TEXT                NOT NULL,
       package_version TEXT                NOT NULL,

       UNIQUE(distribution, package_name)
);

CREATE INDEX idx_ancestry_parent           ON ancestry(parent);
CREATE INDEX idx_ancestry_child            ON ancestry(child);
CREATE INDEX idx_package_sha256            ON package(sha256);
