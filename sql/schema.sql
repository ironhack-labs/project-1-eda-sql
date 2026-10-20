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

CREATE TABLE IF NOT EXISTS participants (
    participant_id INTEGER PRIMARY KEY
);


-- --- Your main table -----------------------------------------------------
-- The rows you are actually analysing: the numbers you care about, plus one
-- foreign key pointing at each lookup table above. Created and loaded LAST,
-- because every key it carries has to already exist somewhere else.


CREATE TABLE IF NOT EXISTS demographics (
    participant_id INTEGER PRIMARY KEY,
    age_years REAL,
    sex TEXT,
    exam_weight REAL,
    education_level TEXT,
    income_poverty_ratio REAL,
    age_group TEXT,
    poverty_group TEXT,

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);



-- =========================================================================
-- Child table: demographics
-- =========================================================================

CREATE TABLE IF NOT EXISTS demographics (
    participant_id INTEGER PRIMARY KEY,
    age_years REAL,
    sex TEXT,
    exam_weight REAL,
    education_level TEXT,
    income_poverty_ratio REAL,
    age_group TEXT,
    poverty_group TEXT,

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);


-- =========================================================================
-- Child table: physical activity
-- =========================================================================

CREATE TABLE IF NOT EXISTS physical_activity (
    participant_id INTEGER PRIMARY KEY,
    moderate_activity_frequency REAL,
    moderate_activity_unit TEXT,
    moderate_activity_minutes REAL,
    vigorous_activity_frequency REAL,
    vigorous_activity_unit TEXT,
    vigorous_activity_minutes REAL,
    sitting_minutes_per_day REAL,
    moderate_minutes_per_week REAL,
    vigorous_minutes_per_week REAL,

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);


-- =========================================================================
-- Child table: body measurements
-- =========================================================================

CREATE TABLE IF NOT EXISTS body_measurements (
    participant_id INTEGER PRIMARY KEY,
    weight_kg REAL,
    height_cm REAL,
    bmi REAL,
    waist_circumference_cm REAL,
    hip_circumference_cm REAL,

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);


-- =========================================================================
-- Child table: blood pressure
-- =========================================================================

CREATE TABLE IF NOT EXISTS blood_pressure (
    participant_id INTEGER PRIMARY KEY,
    average_upper_bp REAL,
    average_lower_bp REAL,

    FOREIGN KEY (participant_id)
        REFERENCES participants(participant_id)
);


-- --- Indexes (optional) --------------------------------------------------
-- Worth adding on your foreign keys if a query starts to feel slow.
