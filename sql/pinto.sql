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

/* TODO: Consider keeping track of if (and possibly when)
   a stack has been merged.  Then only allow a merged
   stack to be deleted.  Similarly, consider marking
   a stack as "deleted" rather than actually deleting it,
   so that you can potentially restore it by rolling it
   back. */

CREATE TABLE stack (
       id          INTEGER PRIMARY KEY NOT NULL,
       name        TEXT                NOT NULL,
       mtime       INTEGER             NOT NULL,
       description TEXT                NOT NULL 
);


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
CREATE        INDEX f ON registry(stack);
CREATE        INDEX g ON package(name);
