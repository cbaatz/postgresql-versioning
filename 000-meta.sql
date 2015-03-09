CREATE SCHEMA meta;
CREATE TABLE meta.version (
    id         INTEGER NOT NULL PRIMARY KEY,
    name       VARCHAR NOT NULL DEFAULT '',
    valid_time TIMESTAMP NOT NULL DEFAULT NOW()
);
