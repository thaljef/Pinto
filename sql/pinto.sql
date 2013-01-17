
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
       name                 TEXT                NOT NULL,
       name_canonical       TEXT                NOT NULL,
       is_default           BOOLEAN             NOT NULL, 
       properties           TEXT                DEFAULT NULL,
       head                 INTEGER             DEFAULT NULL,

       FOREIGN KEY(head) REFERENCES kommit(id)
);



/*

    Join table, representing the relationship between a package and a
    stack.  A package may belong to many stacks, but each package name
    in the stack must be unique.  

*/

CREATE TABLE registration (
       id                   INTEGER PRIMARY KEY NOT NULL,
       kommit               INTEGER             NOT NULL,
       package              INTEGER             NOT NULL, /* Points to the package */
       package_name         TEXT                NOT NULL, /* Name of referenced the package.  Must be unique per stack */
       distribution         INTEGER             NOT NULL, /* Points to the distribution that contains the package */
       is_pinned            BOOLEAN             NOT NULL, /* Boolean, indicates if the package can be changed */

       FOREIGN KEY(kommit)       REFERENCES kommit(id),
       FOREIGN KEY(package)      REFERENCES package(id) ON DELETE CASCADE,
       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE
);


CREATE TABLE kommit (
       id           INTEGER PRIMARY KEY NOT NULL,
       sha256       TEXT                NOT NULL,
       timestamp    REAL                NOT NULL,     /* When the revision was committed (epoch seconds) */
       username     TEXT                NOT NULL,     /* User who committed the revision */
       message      TEXT                NOT NULL      /* Log message for the revision */
);


CREATE TABLE kommit_graph (
       id           INTEGER PRIMARY KEY NOT NULL,
       depth        INTEGER             NOT NULL,
       ancestor     INTEGER             NOT NULL,
       descendant   INTEGER             NOT NULL,

       FOREIGN KEY(ancestor)    REFERENCES kommit(id) ON DELETE CASCADE,
       FOREIGN KEY(descendant)  REFERENCES kommit(id) ON DELETE CASCADE
);


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

/*********************************************************

These next two indexes ensure data integrity (i.e. a package 
appears only once in each kommit), but they make the databse 
very big and slow when there are a lot of kommits.  For now,
I'm going to leave them in (for safety).  We can always
drop them later when Pinto has proven itself reliable.

*********************************************************/

CREATE UNIQUE INDEX h ON registration(kommit, package);
CREATE UNIQUE INDEX i ON registration(kommit, package_name);



CREATE UNIQUE INDEX k ON kommit(sha256);
CREATE UNIQUE INDEX l ON prerequisite(distribution, package_name);
CREATE UNIQUE INDEX m ON repository_property(key);
CREATE UNIQUE INDEX n ON repository_property(key_canonical);

CREATE        INDEX o ON registration(kommit);
CREATE        INDEX p ON package(name);
CREATE        INDEX q ON package(sha256);
CREATE        INDEX r ON package(file);
CREATE        INDEX s ON distribution(author);
CREATE        INDEX t ON kommit_graph(ancestor);
CREATE        INDEX u ON kommit_graph(descendant);
CREATE        INDEX v ON prerequisite(package_name);
