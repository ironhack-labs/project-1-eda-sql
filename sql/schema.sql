-- =========================================================================
-- schema.sql - the tables your database is made of
--
-- Project 1 | SQL: From Data to Insight
-- Team:
-- Dataset:
--
-- This is a DELIVERABLE: it is how someone rebuilds your database from
-- nothing, and the tables here must match the ERD you drew.
--
-- Written for SQLite. On MySQL, add a CREATE DATABASE / USE at the top and
-- swap the types (TEXT -> VARCHAR(n), REAL -> DECIMAL, INTEGER PRIMARY KEY
-- -> INT PRIMARY KEY AUTO_INCREMENT).
-- =========================================================================

-- SQLite does not enforce foreign keys unless you ask it to, once per
-- connection. Without this line a broken key is accepted in silence.
PRAGMA foreign_keys = ON;


-- --- Lookup tables -------------------------------------------------------
-- The categorical columns you pulled out: an id and the value it stands for.
-- These have no foreign keys of their own, so they are created and loaded
-- FIRST.
CREATE TABLE areas (
    area_code INTEGER PRIMARY KEY,
    area_name TEXT NOT NULL
);


-- --- Your main table -----------------------------------------------------
-- The rows you are actually analysing: the numbers you care about, plus one
-- foreign key pointing at each lookup table above. Created and loaded LAST,
-- because every key it carries has to already exist somewhere else.
CREATE TABLE datasets (
    dataset_code TEXT PRIMARY KEY,
    label TEXT,
    date_update TEXT,
    note_update TEXT,
    release_current TEXT,
    state_current TEXT,
    year_current INTEGER,
    release_next TEXT,
    state_next TEXT,
    year_next INTEGER
);


CREATE TABLE fbs_country (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    element_code INTEGER NOT NULL,
    unit TEXT,
    value REAL,
    PRIMARY KEY (area_code, year, element_code),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

CREATE TABLE fbs_products (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    item_code INTEGER NOT NULL,
    item_name TEXT,
    unit TEXT,
    value REAL,
    PRIMARY KEY (area_code, year, item_code),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

CREATE TABLE harvested_area (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    harvested_area_ha REAL,
    PRIMARY KEY (area_code, year),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

CREATE TABLE gdp_per_capita (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    gdp_per_capita REAL,
    PRIMARY KEY (area_code, year),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

CREATE TABLE population (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    unit TEXT,
    population REAL,
    PRIMARY KEY (area_code, year),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

CREATE TABLE fbs_trade (
    dataset_code TEXT NOT NULL,
    area_code INTEGER NOT NULL,
    year INTEGER NOT NULL,
    item_code INTEGER NOT NULL,
    item_name TEXT,
    element_code INTEGER NOT NULL,
    element_name TEXT,
    unit TEXT,
    value REAL,
    PRIMARY KEY (area_code, year, item_code, element_code),
    FOREIGN KEY (dataset_code)
        REFERENCES datasets(dataset_code),
    FOREIGN KEY (area_code)
        REFERENCES areas(area_code)
);

-- --- Indexes (optional) --------------------------------------------------
-- Worth adding on your foreign keys if a query starts to feel slow.
