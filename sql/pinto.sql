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


/* TODO: Add boolean is_merged field to indicate whether
   the stack has been merged since it was last modified */

CREATE TABLE stack (
       id          INTEGER PRIMARY KEY NOT NULL,
       name        TEXT                NOT NULL,
       mtime       INTEGER             NOT NULL,
       description TEXT                DEFAULT NULL 
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


/* TODO: Add a checksum (md5) that captures the state
   of the stack at that point in history.  Use this
   to verify that rollbacks are correct.  This implies
   that a revisions can only happen on one stack at a 
   time.  Not sure I want to commit to that */


CREATE TABLE revision (
       id          INTEGER PRIMARY KEY NOT NULL,
       message     TEXT                NOT NULL,
       username    TEXT                NOT NULL,
       ctime       INTEGER             NOT NULL
);


/*

Reporting ideas...

Rev Stack A Package Pin
Rev Stack R Package Pin
Rev Stack P Package Pin
Rev Stack U Package Pin

*/


CREATE TABLE package_stack_history (
       id                  INTEGER PRIMARY KEY NOT NULL,
       revision            INTEGER             NOT NULL,
       event               TEXT                NOT NULL,
       stack               INTEGER             NOT NULL,
       package             INTEGER             NOT NULL,
       pin                 INTEGER             NOT NULL,

       FOREIGN KEY(revision)  REFERENCES revision(id),
       FOREIGN KEY(stack)     REFERENCES stack(id),
       FOREIGN KEY(package)   REFERENCES package(id)
);

/*
CREATE TABLE dependency (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       prerequisite TEXT                NOT NULL,
       version      TEXT                NOT NULL,
       stage        TEXT                DEFAULT NULL,  
       FOREIGN KEY(distribution)  REFERENCES distribution(id),
);
*/

/* TODO: Put proper indexes in place */

CREATE UNIQUE INDEX distribution_idx      ON distribution(path);
CREATE UNIQUE INDEX package_idx           ON package(name, distribution);
CREATE UNIQUE INDEX stack_name_idx        ON stack(name);
CREATE        INDEX package_name_idx      ON package(name);
