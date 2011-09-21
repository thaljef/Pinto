CREATE TABLE distribution (
       distribution_id INTEGER PRIMARY KEY NOT NULL,
       path TEXT NOT NULL,
       origin TEXT DEFAULT ''
);

CREATE TABLE package (
       package_id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       version_numeric REAL NOT NULL,
       distribution INTEGER NOT NULL,
       is_local BOOLEAN DEFAULT 0,
       should_index BOOLEAN DEFAULT 0,
       FOREIGN KEY(distribution) REFERENCES distribution(distribution_id)
);

CREATE UNIQUE INDEX distribution_idx ON distribution(path);
CREATE INDEX package_name_idx ON package(name);

CREATE UNIQUE INDEX package_idx ON package(name, distribution);
CREATE UNIQUE INDEX package_should_index_idx ON package(name, should_index);

