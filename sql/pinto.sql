CREATE TABLE distribution (
       id INTEGER PRIMARY KEY NOT NULL,
       location TEXT NOT NULL,
       origin TEXT NOT NULL
);

CREATE TABLE package (
       id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       distribution INTEGER,
       FOREIGN KEY(distribution) REFERENCES distribution(id)
);

CREATE UNIQUE INDEX distribution_idx ON distribution(location);
CREATE UNIQUE INDEX package_idx ON package(name, version, distribution);