-- ============================================================
-- QUERY 1
-- Distribution of measurements by electrode material
-- and crystallographic orientation
-- ============================================================

SELECT
    m.material_name,
    o.orientation_name,
    COUNT(me.measurement_id) AS measurement_count
FROM measurements AS me
JOIN materials AS m
    ON me.material_id = m.material_id
JOIN orientations AS o
    ON me.orientation_id = o.orientation_id
GROUP BY
    m.material_name,
    o.orientation_name
ORDER BY
    m.material_name,
    o.orientation_name;
	

	-- ============================================================
-- QUERY 2
-- Electrolyte environments represented for each material
-- ============================================================
SELECT
    mat.material_name,
    e.electrolyte_type,
    e.electrolyte_condition,
    COUNT(me.measurement_id) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
JOIN electrolytes AS e
    ON me.electrolyte_id = e.electrolyte_id
GROUP BY
    mat.material_name,
    e.electrolyte_type,
    e.electrolyte_condition
ORDER BY
    mat.material_name,
    measurement_count DESC;

	
-- ============================================================
-- QUERY 3
-- Scan-rate statistics by electrode material
-- ============================================================

SELECT
    mat.material_name,
    COUNT(me.measurement_id) AS measurement_count,
    ROUND(AVG(me.scan_rate_value), 2) AS mean_scan_rate,
    MIN(me.scan_rate_value) AS minimum_scan_rate,
    MAX(me.scan_rate_value) AS maximum_scan_rate
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
GROUP BY
    mat.material_name
ORDER BY
    mean_scan_rate DESC;
	

	-- ============================================================
-- QUERY 4
-- Scan-rate categories across materials and orientations
-- ============================================================

SELECT
    mat.material_name,
    o.orientation_name,
    me.scan_rate_category,
    COUNT(*) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
JOIN orientations AS o
    ON me.orientation_id = o.orientation_id
GROUP BY
    mat.material_name,
    o.orientation_name,
    me.scan_rate_category
ORDER BY
    mat.material_name,
    o.orientation_name,
    me.scan_rate_category;

	
	-- ============================================================
-- QUERY 5
-- Material/orientation combinations represented by
-- at least 10 measurements
-- ============================================================

SELECT
    mat.material_name,
    o.orientation_name,
    COUNT(*) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
JOIN orientations AS o
    ON me.orientation_id = o.orientation_id
GROUP BY
    mat.material_name,
    o.orientation_name
HAVING
    COUNT(*) >= 10
ORDER BY
    measurement_count DESC;
	
	
	-- ============================================================
-- QUERY 6
-- Measurements whose scan rate is above the overall
-- average scan rate
-- ============================================================

SELECT
    me.measurement_id,
    mat.material_name,
    o.orientation_name,
    me.scan_rate_value,
    me.scan_rate_unit
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
JOIN orientations AS o
    ON me.orientation_id = o.orientation_id
WHERE
    me.scan_rate_value >
    (
        SELECT AVG(scan_rate_value)
        FROM measurements
    )
ORDER BY
    me.scan_rate_value DESC;
	
	
	-- ============================================================
-- QUERY 7
-- Reference-electrode usage by material
-- ============================================================

SELECT
    mat.material_name,
    COALESCE(me.reference_electrode_family, 'Unknown') AS reference_family,
    COUNT(*) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
GROUP BY
    mat.material_name,
    COALESCE(me.reference_electrode_family, 'Unknown')
ORDER BY
    mat.material_name,
    measurement_count DESC;
	
	
	-- ============================================================
-- DATA QUALITY CHECK
-- Current signal units represented in the dataset
-- ============================================================

SELECT
    current_unit,
    COUNT(*) AS measurement_count
FROM measurements
GROUP BY
    current_unit
ORDER BY
    measurement_count DESC;
	
	
 -- ============================================================
others for validation and checks	
-- ============================================================
	
	
SELECT COUNT(*) AS measurement_count
FROM measurements;





SELECT 'materials' AS table_name, COUNT(*) AS row_count
FROM materials

UNION ALL

SELECT 'orientations', COUNT(*)
FROM orientations

UNION ALL

SELECT 'sources', COUNT(*)
FROM sources

UNION ALL

SELECT 'electrolytes', COUNT(*)
FROM electrolytes

UNION ALL

SELECT 'measurements', COUNT(*)
FROM measurements

UNION ALL

SELECT 'cv_points', COUNT(*)
FROM cv_points;


SELECT * FROM materials;

SELECT * FROM orientations;

SELECT
    material_id,
    COUNT(*) AS measurement_count
FROM measurements
GROUP BY material_id;







SELECT
    COUNT(*) AS total_measurements,
    COUNT(mat.material_id) AS matched_materials,
    COUNT(o.orientation_id) AS matched_orientations
FROM measurements AS me
LEFT JOIN materials AS mat
    ON me.material_id = mat.material_id
LEFT JOIN orientations AS o
    ON me.orientation_id = o.orientation_id;
	
	
	
	
	
SELECT COUNT(*) AS measurement_count
FROM measurements;




SELECT 'materials' AS table_name, COUNT(*) AS row_count FROM materials
UNION ALL
SELECT 'orientations', COUNT(*) FROM orientations
UNION ALL
SELECT 'sources', COUNT(*) FROM sources
UNION ALL
SELECT 'electrolytes', COUNT(*) FROM electrolytes
UNION ALL
SELECT 'measurements', COUNT(*) FROM measurements
UNION ALL
SELECT 'cv_points', COUNT(*) FROM cv_points;





SELECT
    mat.material_name,
    o.orientation_name,
    COUNT(me.measurement_id) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
JOIN orientations AS o
    ON me.orientation_id = o.orientation_id
GROUP BY
    mat.material_name,
    o.orientation_name
ORDER BY
    mat.material_name,
    o.orientation_name;