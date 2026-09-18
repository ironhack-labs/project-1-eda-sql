-- =========================================================================
-- queries.sql - your analysis
--
-- Project 1 | SQL: From Data to Insight
-- Team:
-- Dataset:
--
-- This is a DELIVERABLE, and it is graded on two things: the SQL, and what
-- you wrote underneath it. A query with no finding recorded is half an
-- answer - in a month you will not remember what it told you, and neither
-- will whoever is marking it.
--
-- Five queries minimum, each one earning its place by answering a question
-- you wrote down in notebook 01.
--
-- The `-- name:` markers are how notebook 03 pulls a query out of this file
-- instead of holding a copy of it:
--
--     from src.functions import load_query, run_query
--     df = run_query(load_query("price_by_district"), DB)
--
-- Keep the names unique and lowercase_with_underscores.
-- =========================================================================


-- =========================================================================
-- Q1 | <the question, in words a non-technical person would ask>
-- =========================================================================
-- Hypothesis: <what you expected before running it>
-- Finding:    <what came back, with the number that matters>
--
-- name: q1_<short_name>
SELECT
    -- TODO
FROM
    -- TODO
;


-- =========================================================================
-- Q2 | <the question>
-- =========================================================================
-- Hypothesis:
-- Finding:
--
-- name: q2_<short_name>
SELECT
    -- TODO
;


-- =========================================================================
-- Q3 | <the question>
-- =========================================================================
-- Hypothesis:
-- Finding:
--
-- name: q3_<short_name>
SELECT
    -- TODO
;


-- =========================================================================
-- Q4 | <the question>
-- =========================================================================
-- Hypothesis:
-- Finding:
--
-- name: q4_<short_name>
SELECT
    -- TODO
;


-- =========================================================================
-- Q5 | <the question>
-- =========================================================================
-- Hypothesis:
-- Finding:
--
-- name: q5_<short_name>
SELECT
    -- TODO
;



-- =========================================================================
-- Patterns to reach for
--
-- Everything below is from Week 2 Days 3 and 4. It is here as a reminder of
-- the shapes available to you, not as a checklist to tick off - five
-- queries that answer real questions beat eight that exist to show off a
-- keyword. The examples use the Titanic tables from the README so you can
-- see the shape without copying an answer.
-- =========================================================================

-- A join plus a group: the workhorse of this project. The label comes from
-- the lookup table, the number from the fact table.
--
--     SELECT t.class_name,
--            COUNT(*)      AS n_passengers,
--            AVG(p.age)    AS avg_age
--     FROM passengers p
--     JOIN ticket_class t ON p.class_id = t.class_id
--     GROUP BY t.class_name
--     ORDER BY n_passengers DESC;

-- HAVING, to drop the groups too small to trust. WHERE filters rows before
-- grouping; HAVING filters the groups after, which is why an aggregate can
-- appear here and not in a WHERE.
--
--     SELECT t.class_name, AVG(p.age) AS avg_age
--     FROM passengers p
--     JOIN ticket_class t ON p.class_id = t.class_id
--     GROUP BY t.class_name
--     HAVING COUNT(*) >= 30;

-- CASE, to bucket a continuous column into categories you can group by.
--
--     SELECT CASE WHEN age < 18 THEN 'child'
--                 WHEN age < 60 THEN 'adult'
--                 ELSE 'senior' END AS age_band,
--            COUNT(*)               AS n,
--            AVG(survived)          AS survival_rate
--     FROM passengers
--     WHERE age IS NOT NULL
--     GROUP BY age_band;

-- A subquery, to compare each row against a value computed from the whole
-- table - here, who paid more than average.
--
--     SELECT name, age
--     FROM passengers
--     WHERE age > (SELECT AVG(age) FROM passengers);

-- A CTE, which is a subquery you can name and read. Once a query has two
-- levels of nesting, rewrite it as a WITH and it stops being write-only.
--
--     WITH class_stats AS (
--         SELECT class_id, COUNT(*) AS n, AVG(survived) AS rate
--         FROM passengers
--         GROUP BY class_id
--     )
--     SELECT t.class_name, s.n, ROUND(s.rate, 3) AS survival_rate
--     FROM class_stats s
--     JOIN ticket_class t ON s.class_id = t.class_id
--     ORDER BY s.rate DESC;

-- Dates in SQLite are text, and these are the functions that work on them.
-- Grouping by month is how you get a trend line out of a timestamp column.
--
--     SELECT strftime('%Y-%m', created_at) AS month, COUNT(*) AS n
--     FROM some_table
--     GROUP BY month
--     ORDER BY month;

-- A window function: a bonus, and the only way to rank within a group
-- without a self-join. ROW_NUMBER, RANK, LAG and LEAD all work in SQLite.
--
--     SELECT class_name, name, age,
--            RANK() OVER (PARTITION BY class_name ORDER BY age DESC) AS rank_in_class
--     FROM passengers p
--     JOIN ticket_class t ON p.class_id = t.class_id;
