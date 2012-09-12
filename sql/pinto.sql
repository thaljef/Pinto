
CREATE TABLE repository_property (
       id    INTEGER PRIMARY KEY NOT NULL,
       name  TEXT                NOT NULL,
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
       last_modified_on   INTEGER             NOT NULL,
       last_modified_by   TEXT                NOT NULL,

       FOREIGN KEY(head_revision) REFERENCES revision(id)
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


create TABLE registration_history (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       is_pinned    INTEGER             NOT NULL,
       package_name         TEXT        NOT NULL,
       package_version      TEXT        NOT NULL,
       distribution_path    TEXT        NOT NULL,
       created_in_revision  INTEGER     NOT NULL,
       deleted_in_revision  INTEGER     DEFAULT NULL,

       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id),
       FOREIGN KEY(created_in_revision) REFERENCES revision(id),
       FOREIGN KEY(deleted_in_revision) REFERENCES revision(id)
);

/*
CREATE TRIGGER insert_registration AFTER INSERT ON registration
BEGIN
       INSERT INTO registration_history (stack, package, is_pinned, package_name, package_version,
                                         distribution_path, created_in_revision, deleted_in_revision)

                                 VALUES (new.stack, new.package, new.package_name, new.package_version,
                                         new.distribution_path, (SELECT max id FROM revision WHERE revision.stack = new.stack), NULL);
END;
*/

CREATE TRIGGER AFTER INSERT ON registration
BEGIN

       INSERT INTO registration_history SELECT new.*, NULL, NULL from new;
       UPDATE registration_history SET created_in_revision = (SELECT max id FROM revision WHERE revision.stack = new.stack);

END;


CREATE TRIGGER AFTER DELETE ON registration
BEGIN

       INSERT INTO registration_history SELECT new.*, NULL, NULL from new;
       UPDATE registration_history SET deleted_in_revision = (SELECT max id FROM revision WHERE revision.stack = new.stack);

END;


CREATE TABLE prerequisite (
       id           INTEGER PRIMARY KEY NOT NULL,
       distribution INTEGER             NOT NULL,
       package_name    TEXT             NOT NULL,
       package_version TEXT             NOT NULL,
  
       FOREIGN KEY(distribution)  REFERENCES distribution(id)
);


CREATE TABLE revision (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       number       INTEGER             NOT NULL,
       committed_on INTEGER             NOT NULL,
       committed_by TEXT                NOT NULL,
       message      TEXT                NOT NULL,

       FOREIGN KEY(stack)  REFERENCES stack(id)
);


/* Schema::Loader names the indexes for us */
CREATE UNIQUE INDEX a ON distribution(author, archive);
CREATE UNIQUE INDEX b ON package(name, distribution);
CREATE UNIQUE INDEX c ON stack(name);
CREATE UNIQUE INDEX d ON registration(stack, package_name);
CREATE UNIQUE INDEX e ON prerequisite(distribution, package_name);
CREATE UNIQUE INDEX f ON stack_property(stack, name);
CREATE UNIQUE INDEX g ON repository_property(name);
CREATE        INDEX h ON registration(stack);
CREATE        INDEX i ON package(name);
