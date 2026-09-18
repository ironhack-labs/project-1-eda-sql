-- =========================================================================
-- schema.sql - the tables your database is made of
--
-- Project 1 | SQL: From Data to Insight
-- Team:
-- Dataset:
--
-- This is a DELIVERABLE. It is how someone rebuilds your database from
-- nothing, and it is what you put on your ERD slide, so the tables here
-- must match the diagram you drew.
--
-- Written for SQLite. Notebook 02 runs it for you:
--
--     load_to_sql(tables, "../data/project.db", schema_file="../sql/schema.sql")
--
-- On MySQL instead? Add `CREATE DATABASE IF NOT EXISTS your_db;` and
-- `USE your_db;` at the top, and swap the types: TEXT -> VARCHAR(n),
-- INTEGER PRIMARY KEY -> INT PRIMARY KEY AUTO_INCREMENT, REAL -> DECIMAL.
-- =========================================================================

-- SQLite does not enforce foreign keys unless you ask it to, once per
-- connection. Without this line a broken key is accepted in silence.
PRAGMA foreign_keys = ON;


-- -------------------------------------------------------------------------
-- 1. Lookup tables - no foreign keys, so they are created and loaded FIRST
--
-- One per categorical column you pulled out in notebook 02. The
-- `categorical_report` starter in notebook 01 is what found them.
-- -------------------------------------------------------------------------

-- EXAMPLE, from the Titanic walkthrough in the README. Delete it and write
-- your own: the column names below are not in any of the three datasets.
CREATE TABLE IF NOT EXISTS ticket_class (
    class_id    INTEGER PRIMARY KEY,
    class_name  TEXT NOT NULL UNIQUE
);

-- TODO: your first lookup table.
-- CREATE TABLE IF NOT EXISTS ...  (
--     ..._id   INTEGER PRIMARY KEY,
--     ..._name TEXT NOT NULL UNIQUE
-- );

-- TODO: your second lookup table.


-- -------------------------------------------------------------------------
-- 2. Dimension tables - descriptive entities, still no foreign keys
--
-- A dimension is a lookup with attributes: a host has a name, a listing
-- count and a response rate, not just a label. Skip this section if your
-- design does not have one; three tables is the minimum, not a quota of
-- table types.
-- -------------------------------------------------------------------------

-- TODO: your dimension table, if you have one.
-- CREATE TABLE IF NOT EXISTS ... (
--     ..._id     INTEGER PRIMARY KEY,
--     ...        TEXT,
--     ...        REAL
-- );


-- -------------------------------------------------------------------------
-- 3. Fact table - the rows you are actually analysing
--
-- It holds the measures (price, amount, quantity, score) and a foreign key
-- to each table above. Created and loaded LAST, because every key it
-- carries has to already exist somewhere else.
-- -------------------------------------------------------------------------

-- EXAMPLE, again from the Titanic walkthrough. Replace it.
CREATE TABLE IF NOT EXISTS passengers (
    passenger_id  INTEGER PRIMARY KEY,
    name          TEXT,
    class_id      INTEGER,
    age           REAL,
    survived      INTEGER,
    FOREIGN KEY (class_id) REFERENCES ticket_class(class_id)
);

-- TODO: your fact table.
-- CREATE TABLE IF NOT EXISTS ... (
--     ..._id    INTEGER PRIMARY KEY,
--     <measures: REAL / INTEGER / TEXT>,
--     <one FK column per table above>,
--     FOREIGN KEY (..._id) REFERENCES ...(..._id)
-- );


-- -------------------------------------------------------------------------
-- 4. Indexes (optional, and a tick towards the Advanced Features bonus)
--
-- An index makes filtering and joining on a column faster. Worth adding on
-- your foreign keys once the database is loaded and a query feels slow -
-- on a million-row table like Online Retail II you will notice.
-- -------------------------------------------------------------------------

-- CREATE INDEX IF NOT EXISTS idx_passengers_class ON passengers(class_id);


-- -------------------------------------------------------------------------
-- Sanity checks - run these in DB Browser after notebook 02 has loaded
-- -------------------------------------------------------------------------

-- Every table that exists, and its definition:
--     SELECT name, sql FROM sqlite_master WHERE type = 'table';

-- Row count per table. A 0 means the load failed, usually because a child
-- table went in before its parent:
--     SELECT COUNT(*) FROM ticket_class;
--     SELECT COUNT(*) FROM passengers;

-- Any orphaned foreign keys. This MUST return no rows:
--     SELECT p.passenger_id, p.class_id
--     FROM passengers p
--     LEFT JOIN ticket_class t ON p.class_id = t.class_id
--     WHERE p.class_id IS NOT NULL AND t.class_id IS NULL;
