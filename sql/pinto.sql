DROP TABLE IF EXISTS distribution;
CREATE TABLE distribution (
       id INTEGER PRIMARY KEY,
       location TEXT NOT NULL,
       author INTEGER NOT NULL,
       is_local INTEGER NOT NULL,
       source TEXT NOT NULL,
       FOREIGN KEY(author) REFERENCES author(id)     
);

DROP TABLE IF EXISTS package;
CREATE TABLE package (
       id INTEGER PRIMARY KEY,
       name TEXT NOT NULL,
       version TEXT NOT NULL,
       distribution INTEGER NOT NULL,
       FOREIGN KEY(distribution) REFERENCES distribution(id)
);

DROP TABLE IF EXISTS author;
CREATE TABLE author (
       id INTEGER PRIMARY KEY,
       name TEXT,
       email TEXT
);