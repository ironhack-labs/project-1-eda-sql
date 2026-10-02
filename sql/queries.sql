-- =========================================================================
-- queries.sql
--
-- Project 1 | SQL: From Data to Insight
-- 
-- Dataset: FAOSTAT
--
-- =========================================================================


-- =========================================================================
-- Q1 | How does dietary energy supply (DES, kcal/person/day) differ across countries and regions, by year?
-- =========================================================================
-- Hypothesis: DES differs substantially across countries.
-- Finding: Confirmed.

SELECT
    a.area_name,
    f.year,
    f.value AS des
FROM fbs_country AS f
JOIN areas AS a
    ON f.area_code = a.area_code
ORDER BY
    f.year,
    des DESC;

-- =========================================================================
-- Q2 | Which countries show the strongest increase or decline in DES over time?
-- =========================================================================
-- Hypothesis: Some countries show clear positive or negative DES trends over time.
-- Finding: Significant changes have been observed for particular countries

SELECT
    a.area_name,
    f.year,
    f.value AS des
FROM fbs_country AS f
JOIN areas AS a
    ON f.area_code = a.area_code
ORDER BY
    f.year,
    des DESC;

-- =========================================================================
-- Q3 | Which food products/groups contribute most to DES, and how does this composition differ by year?
-- =========================================================================
-- Hypothesis: A relatively small number of food products account for a large share of DES.
-- Finding: Vegetal products and particularly cereals are the largest contributors to average DES.

SELECT
    item_name, 
    year,
    AVG(value) AS avg_des
FROM fbs_products
GROUP BY
    year,
    item_code,
    item_name
ORDER BY 
    year,
    avg_des DESC;

-- =========================================================================
-- Q4 | Which food products/groups show the strongest increase or decline in their contribution to DES over time?
-- =========================================================================
-- Hypothesis: Some products/groups show clear positive or negative DES trends over time.
-- Finding: Vegetable oils, meat and milk increased, while several sugar and grain products declined.

SELECT
    item_code,
    item_name,
    year,
    AVG(value) AS avg_des
FROM fbs_products
GROUP BY
    year,
    item_code,
    item_name
ORDER BY 
    year,
    avg_des DESC;

-- =========================================================================
-- Q5 | Does harvested agricultural area per person relate to dietary energy supply, and which countries have relatively high harvested area per person but low DES?
-- =========================================================================
-- Hypothesis: Countries with more harvested area per person should have higher DES, but there might be exceptions.
-- Finding: Harvested area per person shows no clear strong relationship with DES, while some extreme cases were observed.

SELECT
    a.area_name,
    h.year,
    h.harvested_area_ha,
    p.population,
    d.value AS des,
    h.harvested_area_ha / (p.population * 1000.0)
        AS harvested_area_per_person
FROM harvested_area AS h
JOIN areas AS a
    ON h.area_code = a.area_code
JOIN population AS p
    ON h.area_code = p.area_code
    AND h.year = p.year
JOIN fbs_country AS d
    ON h.area_code = d.area_code
    AND h.year = d.year
WHERE d.element_code = 664
  AND p.population > 0
ORDER BY h.year, a.area_name;


-- =========================================================================
-- Q6 | Which food product groups are most associated with rising imports and declining domestic production as GDP per capita grows?
-- =========================================================================
-- Hypothesis: Production of certain food commodities declines and import increases as GDP grows.
-- Finding: Only a few product groups match the expected pattern, and most correlations are weak.

SELECT
    a.area_name,
    t.area_code,
    t.year,
    t.item_code,
    t.item_name,
    t.element_name,
    t.value,
    g.gdp_per_capita
FROM fbs_trade AS t
JOIN gdp_per_capita AS g
    ON t.area_code = g.area_code
    AND t.year = g.year
JOIN areas AS a
    ON t.area_code = a.area_code
WHERE t.area_code < 5000    
ORDER BY
    a.area_name,
    t.item_name,
    t.year;