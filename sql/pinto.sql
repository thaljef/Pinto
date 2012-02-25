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
       is_latest BOOLEAN DEFAULT NULL,
       distribution INTEGER NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(id)
);


CREATE TABLE stack (
       id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       mtime INTEGER NOT NULL,
       description TEXT DEFAULT NULL 
);


create TABLE package_stack (
       id      INTEGER PRIMARY KEY NOT NULL,
       stack   INTEGER             NOT NULL,
       package INTEGER             NOT NULL,
       FOREIGN KEY(stack)   REFERENCES stack(id),
       FOREIGN KEY(package) REFERENCES package(id)
);


CREATE UNIQUE INDEX distribution_idx      ON distribution(path);
CREATE UNIQUE INDEX package_idx           ON package(name, distribution);
CREATE UNIQUE INDEX package_is_latest_idx ON package(name, is_latest);
CREATE UNIQUE INDEX stack_idx             ON stack(name);
CREATE        INDEX package_name_idx      ON package(name);
