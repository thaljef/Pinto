CREATE TABLE distribution (
       id INTEGER PRIMARY KEY NOT NULL,
       location TEXT NOT NULL UNIQUE,
       origin TEXT NOT NULL
);

CREATE TABLE package (
       id INTEGER PRIMARY KEY NOT NULL,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       distribution INTEGER,
       FOREIGN KEY(distribution) REFERENCES distribution(id) ON DELETE CASCADE
);
