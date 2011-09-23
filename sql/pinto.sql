CREATE TABLE distribution (
       distribution_id INTEGER PRIMARY KEY NOT NULL,
       path TEXT NOT NULL,
       origin TEXT DEFAULT '',
       is_local BOOLEAN DEFAULT 0,
       is_devel BOOLEAN DEFAULT 0
);


CREATE TABLE package (
       package_id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       version_numeric REAL NOT NULL,
       should_index BOOLEAN DEFAULT 0,
       distribution INTEGER NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(distribution_id)
);


CREATE UNIQUE INDEX distribution_idx ON distribution(path);
CREATE INDEX package_name_idx ON package(name);


CREATE UNIQUE INDEX package_idx ON package(name, distribution);
CREATE UNIQUE INDEX package_should_index_idx ON package(name, should_index);

