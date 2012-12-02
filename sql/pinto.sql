
/* 

   Represents a key-value pair that defines a global attribute of the
   repository.  Each key must be unique.

*/

CREATE TABLE repository_property (
       id              INTEGER PRIMARY KEY NOT NULL,
       key             TEXT                NOT NULL,  /* SchemaVersion */
       key_canonical   TEXT                NOT NULL,  /* schemaversion */
       value           TEXT                DEFAULT '' /* 1.2.4         */
);

/*

   Represents a distribution archive (e.g. Foo-Bar-1.0.tar.gz).
   Each author/archive combination must be unqiue.  Also, no two
   archives can have the same content, so the sha256 and md5 must
   also be unique.

*/

CREATE TABLE distribution (
       id                INTEGER PRIMARY KEY NOT NULL,
       author            TEXT                NOT NULL, /* BigJim */
       author_canonical  TEXT                NOT NULL, /* BIGJIM */
       archive           TEXT                NOT NULL, /* Foo-Bar-1.0.tar.gz */
       source            TEXT                NOT NULL, /* http://cpan.perl.org/authors/id/B/BI/BIGJIM/Foo-Bar-1.0.tar.gz */
       mtime             INTEGER             NOT NULL, /* last-modified time of the archive file */
       sha256            TEXT                NOT NULL, /* SHA-256 digest of the archive file */
       md5               TEXT                NOT NULL  /* MD5 digest of the archive file */
);

/*

    Represents a package contained in a distribution.  Within
    any given distribution, each package name must be unqiue.

*/

CREATE TABLE package (
       id            INTEGER PRIMARY KEY NOT NULL,
       name          TEXT                NOT NULL,     /* Foo::Bar */
       version       TEXT                NOT NULL,     /* 1.2.3 */
       file          TEXT                DEFAULT NULL, /* Path to the file containing the package */
       sha256        TEXT                DEFAULT NULL, /* SHA-256 digest of the module file */
       distribution  INTEGER             NOT NULL,     /* The distribution that contains this package */

       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE
);


/*

    Represents a named collection of packages.  Each stack corresponds
    to an 02packages.details file.  Each stack name must be unique.

*/


CREATE TABLE stack (
       id                   INTEGER PRIMARY KEY NOT NULL,
       name                 TEXT                NOT NULL,     /* MyStack */
       name_canonical       TEXT                NOT NULL,     /* mystack */
       is_default           BOOLEAN             NOT NULL,     /* Boolean flag, indicates if this is the default stack in the repository */
       properties           TEXT                DEFAULT NULL  /* Hash as JSON string */
);



/*

    Join table, representing the relationship between a package and a
    stack.  A package may belong to many stacks, but each package name
    in the stack must be unique.  

*/

CREATE TABLE registration (
       id                   INTEGER PRIMARY KEY NOT NULL,
       stack                INTEGER             NOT NULL,
       package              INTEGER             NOT NULL, /* Points to the package */
       package_name         TEXT                NOT NULL, /* Name of referenced the package.  Must be unique per stack */
       distribution         INTEGER             NOT NULL, /* Points to the distribution that contains the package */
       is_pinned            BOOLEAN             NOT NULL, /* Boolean, indicates if the package can be changed */

       FOREIGN KEY(stack)        REFERENCES stack(id) ON DELETE CASCADE,
       FOREIGN KEY(package)      REFERENCES package(id) ON DELETE CASCADE,
       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE
);

/*

   Audit table, representing a change to the registration table.  The
   registration table can only be modified by insert or deleting
   records (updates are not permitted).  So this table makes a record
   of each addition or deleteion, and associates it with a revision.
   A revision may include multiple insertions or deletions.

*/

CREATE TABLE registration_change (
       id            INTEGER PRIMARY KEY NOT NULL,
       event         TEXT                NOT NULL, /* INSERT or DELETE */
       package       INTEGER             NOT NULL, /* Points to the package that was registered */
       package_name  TEXT                NOT NULL, /* Name of the referenced package.  Must be unique per kommit */
       distribution  INTEGER             NOT NULL, /* Points to the distribution that contained the package */
       is_pinned     BOOLEAN             NOT NULL, /* Boolean, indicates if the package can be changed */
       kommit        INTEGER             NOT NULL, /* Points to commit in which this change ocurred */

       FOREIGN KEY(package)      REFERENCES package(id) ON DELETE CASCADE,
       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE,
       FOREIGN KEY(kommit)       REFERENCES kommit(id) ON DELETE CASCADE
);


/*

    Represents a set of changes (i.e. a set of records in the
    registration_changes table).  Each revision is associated with
    exactly one stack, and has a sequential revision number for that
    stack (i.e. the first revision in any stack is numbered "1").  

*/


CREATE TABLE kommit (
       id           INTEGER PRIMARY KEY NOT NULL,
       is_committed BOOLEAN             NOT NULL,     /* Boolean, indicates if the revision has been committed yet */
       committed_on INTEGER             NOT NULL,     /* When the revision was committed (epoch seconds) */
       committed_by TEXT                NOT NULL,     /* User who committed the revision */
       message      TEXT                NOT NULL      /* Log message for the revision */
);


/*

    Join table.  Associates a kommit with one or more stacks.  When
    a stack is copied, all of its revisions are also copied

*/

CREATE TABLE revision (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,  /* Points to the stack where the changes ocurred */
       kommit       INTEGER             NOT NULL,  /* Points to the kommit that describes the changes */
       number       INTEGER             NOT NULL,  /* Sequential revision number (1,2,3...N) */

       FOREIGN KEY(stack)  REFERENCES stack(id) ON DELETE CASCADE,
       FOREIGN KEY(kommit) REFERENCES kommit(id) ON DELETE CASCADE
);

/*

    Represents a prerequisite (i.e. dependency) for a distribution
    archive.  Note that distribution archives depend only on a package
    name & version, not a particular record in the package table.
    Each package name that is required for a given distribution
    archive must be unique.


*/

CREATE TABLE prerequisite (
       id              INTEGER PRIMARY KEY NOT NULL,
       distribution    INTEGER             NOT NULL, /* Points to the distribution that declared these prereqs */
       package_name    TEXT                NOT NULL, /* Foo::Bar */
       package_version TEXT                NOT NULL, /* 1.2.3 */
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id) ON DELETE CASCADE
);

/* Schema::Loader names the indexes for us */
CREATE UNIQUE INDEX a ON distribution(author_canonical, archive);
CREATE UNIQUE INDEX b ON distribution(md5);
CREATE UNIQUE INDEX c ON distribution(sha256);
CREATE UNIQUE INDEX d ON package(name, distribution);
CREATE UNIQUE INDEX e ON stack(name);
CREATE UNIQUE INDEX f ON stack(name_canonical);
CREATE UNIQUE INDEX g ON registration(stack, package);
CREATE UNIQUE INDEX h ON registration(stack, package_name);
CREATE UNIQUE INDEX i ON registration_change(event, package, kommit) ON CONFLICT REPLACE;
CREATE UNIQUE INDEX j ON registration_change(event, package_name, kommit) ON CONFLICT REPLACE;
CREATE UNIQUE INDEX k ON revision(stack, kommit);
CREATE UNIQUE INDEX l ON revision(stack, number);
CREATE UNIQUE INDEX m ON prerequisite(distribution, package_name);
CREATE UNIQUE INDEX n ON repository_property(key);
CREATE UNIQUE INDEX o ON repository_property(key_canonical);

CREATE        INDEX p ON registration(stack);
CREATE        INDEX q ON package(name);
CREATE        INDEX r ON package(sha256);
CREATE        INDEX s ON package(file);
CREATE        INDEX t ON distribution(author);
CREATE        INDEX u ON prerequisite(package_name);
