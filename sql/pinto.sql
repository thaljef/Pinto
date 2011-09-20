CREATE TABLE distribution (
       distribution_id INTEGER PRIMARY KEY NOT NULL,
       path TEXT NOT NULL,
       origin TEXT NOT NULL
);

CREATE TABLE package (
       package_id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       version_numeric REAL NOT NULL,
       distribution INTEGER NOT NULL,
       is_latest BOOLEAN,
       FOREIGN KEY(distribution) REFERENCES distribution(distribution_id)
);

CREATE UNIQUE INDEX distribution_idx ON distribution(path);
CREATE UNIQUE INDEX package_idx ON package(name, distribution);
CREATE UNIQUE INDEX package_latest_idx ON package(name, is_latest);
CREATE INDEX package_name_idx ON package(name);
