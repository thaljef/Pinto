
CREATE TABLE distribution (
       id      INTEGER PRIMARY KEY NOT NULL,
       path    TEXT                NOT NULL,
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
       last_modified_on   INTEGER             NOT NULL,
       last_modified_by   TEXT                NOT NULL
);


CREATE TABLE stack_property (
       id          INTEGER PRIMARY KEY NOT NULL,
       stack       INTEGER             NOT NULL,
       name        TEXT                NOT NULL,
       value       TEXT                DEFAULT '',
       FOREIGN KEY(stack)   REFERENCES stack(id)
);


create TABLE registration (
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


CREATE TABLE prerequisite (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       package_name    TEXT             NOT NULL,
       package_version TEXT             NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id)
);


/* Schema::Loader names the indexes for us */
CREATE UNIQUE INDEX a ON distribution(path);
CREATE UNIQUE INDEX b ON package(name, distribution);
CREATE UNIQUE INDEX c ON stack(name);
CREATE UNIQUE INDEX d ON registration(stack, package_name);
CREATE UNIQUE INDEX e ON prerequisite(distribution, package_name);
CREATE UNIQUE INDEX f ON stack_property(stack, name);
CREATE        INDEX g ON registration(stack);
CREATE        INDEX h ON package(name);
