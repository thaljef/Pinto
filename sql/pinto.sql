CREATE TABLE distribution (
       distribution_id INTEGER PRIMARY KEY NOT NULL,
       path TEXT NOT NULL,
       source TEXT NOT NULL,
       mtime INTEGER NOT NULL
);


CREATE TABLE package (
       package_id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       is_latest BOOLEAN DEFAULT NULL,
       is_pinned BOOLEAN DEFAULT NULL,
       distribution INTEGER NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(distribution_id)
);


CREATE UNIQUE INDEX distribution_idx ON distribution(path);
CREATE UNIQUE INDEX package_idx ON package(name, distribution);
CREATE UNIQUE INDEX package_is_latest_idx ON package(name, is_latest);
CREATE UNIQUE INDEX package_is_pinned_idx ON package(name, is_pinned);
CREATE INDEX package_name_idx ON package(name);
