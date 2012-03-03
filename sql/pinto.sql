CREATE TABLE distribution (
       id INTEGER PRIMARY KEY NOT NULL,
       path TEXT NOT NULL,
       source TEXT NOT NULL,
       mtime INTEGER NOT NULL
);


CREATE TABLE package (
       id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       distribution INTEGER NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(id)
);


CREATE TABLE stack (
       id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       mtime INTEGER NOT NULL,
       description TEXT DEFAULT NULL 
);


create TABLE pin (
       id INTEGER PRIMARY KEY NOT NULL,
       ctime INTEGER NOT NULL,
       reason TEXT NOT NULL
);


create TABLE package_stack (
       id           INTEGER PRIMARY KEY NOT NULL,
       stack        INTEGER             NOT NULL,
       package      INTEGER             NOT NULL,
       pin          INTEGER             DEFAULT NULL,
       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id),
       FOREIGN KEY(pin)     REFERENCES pin(id)
);


CREATE UNIQUE INDEX distribution_idx      ON distribution(path);
CREATE UNIQUE INDEX package_idx           ON package(name, distribution);
CREATE UNIQUE INDEX stack_idx             ON stack(name);
CREATE        INDEX package_name_idx      ON package(name);
