/* TODO: store dists as author and filename */

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
       id          INTEGER PRIMARY KEY NOT NULL,
       name        TEXT                NOT NULL,
       description TEXT                NOT NULL,       
       mtime       INTEGER             NOT NULL
);


CREATE TABLE stack_property (
       id          INTEGER PRIMARY KEY NOT NULL,
       stack       INTEGER             NOT NULL,
       name        TEXT                NOT NULL,
       value       TEXT                NOT NULL,
       FOREIGN KEY(stack)   REFERENCES stack(id)
);

/* TODO: rename name => package_name */
/* TODO: rename path => distribution_path */

create TABLE registry (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       is_pinned    INTEGER             NOT NULL,
       name         TEXT                NOT NULL,
       version      TEXT                NOT NULL,
       path         TEXT                NOT NULL,

       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id)
);

/* TODO: rename name => package_name */
/* TODO: rename path => distribution_path */

CREATE TABLE prerequisite (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       name         TEXT                NOT NULL,
       version      TEXT                NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id)
);


/* Schema::Loader names the indexes for us */
CREATE UNIQUE INDEX a ON distribution(path);
CREATE UNIQUE INDEX b ON package(name, distribution);
CREATE UNIQUE INDEX c ON stack(name);
CREATE UNIQUE INDEX d ON registry(stack, name);
CREATE UNIQUE INDEX e ON prerequisite(distribution, name);
CREATE UNIQUE INDEX f ON stack_property(stack, name);
CREATE        INDEX g ON registry(stack);
CREATE        INDEX h ON package(name);
