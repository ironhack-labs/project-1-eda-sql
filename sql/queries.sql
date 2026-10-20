-- =========================================================================
-- queries.sql - your analysis
--
-- Project 1 | SQL: From Data to Insight
-- Team:
-- Dataset:
--
-- This is a DELIVERABLE, graded on two things: the SQL, and what you wrote
-- underneath it. A query with no finding recorded is half an answer - in a
-- month you will not remember what it told you, and neither will whoever is
-- marking it.
--
-- Five queries minimum, each earning its place by answering a question you
-- wrote down in notebook 01. The aggregation should happen here, in SQL,
-- not in pandas after a SELECT *.
-- =========================================================================


-- =========================================================================
-- Q1 | How does average blood pressure differ across age groups?
-- =========================================================================
-- Hypothesis: Older adults will have higher average blood pressure than
-- younger adults.
-- Finding:    Older adults are having slightly higher upper bound blood 
-- presure compare to other adults with average 128.94.
SELECT
    d.age_group,
    ROUND(AVG(b.average_upper_bp), 2) AS avg_upper_bp,
    ROUND(AVG(b.average_lower_bp), 2) AS avg_lower_bp
FROM demographics d
JOIN blood_pressure b
    ON d.participant_id = b.participant_id
GROUP BY d.age_group;



-- =========================================================================
-- Q2 | How does average blood pressure differ between males and females?
-- =========================================================================
-- Hypothesis: Average blood pressure will differ between males and females.
-- Finding: the average of Upper bound blood presure in male with 125.4 is
-- a bit higher than female with 120.97

SELECT
    d.sex,
    ROUND(AVG(b.average_upper_bp), 2) AS avg_upper_bp,
    ROUND(AVG(b.average_lower_bp), 2) AS avg_lower_bp
FROM demographics d
JOIN blood_pressure b
    ON d.participant_id = b.participant_id
GROUP BY d.sex;



-- =========================================================================
-- Q3 | How does average BMI differ across age groups?
-- =========================================================================
-- Hypothesis: Average BMI will differ across the three age groups.
-- Finding: BMI does not differ between the different age group but all of 
-- them are categorised as overweight

SELECT
    d.age_group,
    ROUND(AVG(bm.bmi), 2) AS avg_bmi
FROM demographics d
JOIN body_measurements bm
    ON d.participant_id = bm.participant_id
GROUP BY d.age_group;



-- =========================================================================
-- Q4 | How does weekly physical activity differ across age groups?
-- =========================================================================
-- Hypothesis: Younger adults will report more moderate and vigorous physical
-- activity per week than older adults.
-- Finding: Middel-aged addults are having the highest average 
-- moderate and vigorous activity per week almost two times more.

SELECT
    d.age_group,
    ROUND(AVG(pa.moderate_minutes_per_week), 2)
        AS avg_moderate_minutes_week,
    ROUND(AVG(pa.vigorous_minutes_per_week), 2)
        AS avg_vigorous_minutes_week
FROM demographics d
JOIN physical_activity pa
    ON d.participant_id = pa.participant_id
GROUP BY d.age_group;


-- =========================================================================
-- Q5 |What characteristics do the 20 participants with the highest
--      average systolic blood pressure have?
-- =========================================================================
-- Hypothesis: Participants with the highest systolic blood pressure will
-- mainly belong to older age groups and may show higher BMI and lower
-- physical activity levels.
-- Finding: Yes they are mostly older adults and having a bmi higher 
-- than 25 which will be categorise in over weight.

SELECT
    b.participant_id,
    d.age_group,
    d.sex,
    b.average_upper_bp,
    bm.bmi,
    pa.moderate_minutes_per_week,
    pa.vigorous_minutes_per_week
FROM blood_pressure b
JOIN demographics d
    ON b.participant_id = d.participant_id
JOIN body_measurements bm
    ON b.participant_id = bm.participant_id
JOIN physical_activity pa
    ON b.participant_id = pa.participant_id
ORDER BY b.average_upper_bp DESC
LIMIT 20;

-- =========================================================================
-- Q6 | Among the 20 participants with the highest average systolic blood
--      pressure, what are their BMI and weekly physical activity levels?
-- =========================================================================
-- Hypothesis: Participants with the highest systolic blood pressure will
-- tend to have higher BMI and lower weekly physical activity.
-- Finding: they mostly older adults to have mostly 0 minutes vigouros 
-- activity per week and low moderat activity per week and mostly with overweight bmi  

SELECT
    b.participant_id,
    d.age_group,
    d.sex,
    b.average_upper_bp,
    bm.bmi,
    pa.moderate_minutes_per_week,
    pa.vigorous_minutes_per_week

FROM blood_pressure b

JOIN demographics d
    ON b.participant_id = d.participant_id

JOIN body_measurements bm
    ON b.participant_id = bm.participant_id

JOIN physical_activity pa
    ON b.participant_id = pa.participant_id

ORDER BY b.average_upper_bp DESC
LIMIT 20;
