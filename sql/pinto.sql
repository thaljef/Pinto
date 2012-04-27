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

/* TOOD: Denormalize this table to include package name,
   version, and dist path.  Then use indexes to ensure
   data integrity.  This might also make it faster to
   generate indexes, which will be important when we
   need to do it on the fly.  Then also, consider
   renaming this table to something like "index" */

create TABLE package_stack (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       is_pinned    INTEGER             NOT NULL,

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

/* TODO: Put proper indexes in place */

CREATE UNIQUE INDEX distribution_idx      ON distribution(path);
CREATE UNIQUE INDEX package_idx           ON package(name, distribution);
CREATE UNIQUE INDEX stack_name_idx        ON stack(name);
CREATE        INDEX package_name_idx      ON package(name);
