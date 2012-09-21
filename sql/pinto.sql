
CREATE TABLE repository_property (
       id    INTEGER PRIMARY KEY NOT NULL,
       key   TEXT                NOT NULL,
       value TEXT                DEFAULT ''
);


CREATE TABLE distribution (
       id      INTEGER PRIMARY KEY NOT NULL,
       author  TEXT                NOT NULL,
       archive TEXT                NOT NULL,
       source  TEXT                NOT NULL,
       mtime   INTEGER             NOT NULL,
       md5     TEXT                NOT NULL,
       sha256  TEXT                NOT NULL
);


CREATE TABLE package (
       id            INTEGER PRIMARY KEY NOT NULL,
       name          TEXT                NOT NULL,
       version       TEXT                NOT NULL,
       distribution  INTEGER             NOT NULL,

       FOREIGN KEY(distribution) REFERENCES distribution(id)
);


CREATE TABLE stack (
       id                 INTEGER PRIMARY KEY NOT NULL,
       name               TEXT                NOT NULL,
       is_default         INTEGER             NOT NULL,
       head_revision      INTEGER             NOT NULL,
       has_changed        INTEGER             NOT NULL,

       FOREIGN KEY(head_revision) REFERENCES revision(id)
);


CREATE TABLE stack_property (
       id          INTEGER PRIMARY KEY NOT NULL,
       stack       INTEGER             NOT NULL,
       key         TEXT                NOT NULL,
       value       TEXT                DEFAULT '',

       FOREIGN KEY(stack)   REFERENCES stack(id)
);


CREATE TABLE registration (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       is_pinned    INTEGER             NOT NULL,
       package_name         TEXT        NOT NULL,
       package_version      TEXT        NOT NULL,
       distribution_path    TEXT        NOT NULL,

       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id)
);


CREATE TABLE registration_change (
       id           INTEGER PRIMARY KEY NOT NULL,
       event        TEXT                NOT NULL,
       package      INTEGER             NOT NULL,
       is_pinned    INTEGER             NOT NULL,
       revision     INTEGER             NOT NULL,

       FOREIGN KEY(package)  REFERENCES package(id),
       FOREIGN KEY(revision) REFERENCES revision(id)
);


CREATE TABLE prerequisite (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       package_name    TEXT             NOT NULL,
       package_version TEXT             NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id)
);


CREATE TABLE revision (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             DEFAULT NULL,
       number       INTEGER             NOT NULL,
       is_committed INTEGER             NOT NULL,       
       committed_on INTEGER             NOT NULL,
       committed_by TEXT                NOT NULL,
       message      TEXT                NOT NULL,
       md5          TEXT                DEFAULT '',

       FOREIGN KEY(stack)  REFERENCES stack(id)
);


/* Schema::Loader names the indexes for us */
CREATE UNIQUE INDEX a ON distribution(author, archive);
CREATE UNIQUE INDEX b ON distribution(md5);
CREATE UNIQUE INDEX c ON distribution(sha256);
CREATE UNIQUE INDEX d ON package(name, distribution);
CREATE UNIQUE INDEX e ON stack(name);
CREATE UNIQUE INDEX f ON stack(head_revision);
CREATE UNIQUE INDEX g ON registration(stack, package_name);
CREATE UNIQUE INDEX h ON registration(stack, package);
CREATE UNIQUE INDEX i ON registration_change(event, package, is_pinned, revision);
CREATE UNIQUE INDEX j ON revision(stack, number);
CREATE UNIQUE INDEX k ON prerequisite(distribution, package_name);
CREATE UNIQUE INDEX l ON stack_property(stack, key);
CREATE UNIQUE INDEX m ON repository_property(key);

CREATE        INDEX n ON registration(stack);
CREATE        INDEX o ON package(name);
CREATE        INDEX p ON distribution(author);
