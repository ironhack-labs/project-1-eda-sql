# ElectroCatalysisDB: From Cyclic Voltammetry Data to SQL-Based Insight

## Project 1 --- SQL: From Data to Insight

A complete data-analysis and database-engineering project that
transforms electrochemical cyclic voltammetry (CV) data from echemdb
into a cleaned, normalized relational database and uses Python,
Pandas, SQLite, SQL Queries/Analysis, Matplotlib, and Seaborn to extract 
structured insights.

The project demonstrates an end-to-end data workflow:

Dataset identification → acquisition → extraction → cleaning →
transformation → categorical encoding → relational/lookup-table
generation → CSV export → SQLite schema creation → database loading →
SQL querying → hypothesis testing → visualization → interpretation →
validation

------------------------------------------------------------------------

## 1. Project Overview

Electrochemical datasets are often generated from different publications
and experimental laboratories. As a result, metadata can vary
substantially in naming conventions, units, electrolyte descriptions,
electrode configurations, and available experimental information.

This project uses a defined subset of echemdb to investigate how
cyclic voltammetry measurements are distributed across:

-   electrode material: Pt and Au
-   working-electrode type: single crystal
-   crystallographic orientation: (100), (110), and (111)
-   electrolyte environments
-   reported CV scan rates
-   reference and counter electrodes
-   digitized CV data points

The objective is not to rank electrode materials or claim intrinsic
electrochemical performance. Instead, the project demonstrates how
heterogeneous scientific data can be transformed into a structured
relational database and analyzed reproducibly.

------------------------------------------------------------------------

## 2. Dataset Identification

### Source

The dataset was obtained from echemdb, an open electrochemical
database containing curated experimental electrochemistry data and
digitized curves.

The database was accessed programmatically using the Python echemdb
interface.

The project used:

``` python
from echemdb import Echemdb

db = Echemdb.from_remote(version="0.9.2")
```

The selected echemdb release contains:

-   93 references
-   358 entries
-   multiple electrode materials, including Ag, Au, Co, Cu, Fe, Ir, Ni,
    Pb, Pd, Pt, Rh, and Ru

### Why this dataset?

echemdb was selected because it:

1.  contains real scientific measurements rather than synthetic data;
2.  is directly related to my electrochemistry background;
3.  contains structured metadata as well as digitized CV curves;
4.  provides sufficient records for relational database design;
5.  contains categorical and numerical variables suitable for SQL
    analysis;
6.  demonstrates realistic data-quality challenges found in scientific
    datasets.

------------------------------------------------------------------------

## 3. Dataset Scope and Filtering

The original database was narrowed to a clearly defined scientific
scope.

### Step 1 --- Select Pt and Au

``` python
pt_au_db = db.filter(
    lambda entry:
        entry.get_electrode("WE").material in ["Pt", "Au"]
)
```

Result:

-   62 references
-   270 entries

### Step 2 --- Select single-crystal working electrodes

The final filter retained:

-   Pt and Au
-   working-electrode type = single crystal
-   crystallographic orientation = 100, 110, and 111

``` python
filtered_db = db.filter(
    lambda entry:
        entry.get_electrode("WE").material in ["Pt", "Au"]
        and entry.get_electrode("WE").type == "single crystal"
        and entry.get_electrode("WE").crystallographicOrientation
            in ["111", "100", "110"]
)
```

Final dataset:

  Measure                   Count
  --------------------- ---------
  References                   53
  CV measurements             207
  Digitized CV points     704,968
  Materials                     2
  Orientations                  3

The selected measurements are all cyclic voltammetry records.

------------------------------------------------------------------------

# 4. Research Questions

The project was designed around two descriptive research questions.

## Research Question 1

**How are Pt and Au single-crystal CV measurements distributed across
crystallographic orientations?**

### Hypothesis

The measurements are not evenly distributed across the three
crystallographic orientations (100, 110, and 111).

This hypothesis concerns the distribution of records in the selected
literature dataset. It does **not** claim that a more frequently
represented orientation is intrinsically more active or scientifically
more important.

------------------------------------------------------------------------

## Research Question 2

**How do reported scan rates vary across Pt and Au single-crystal
electrodes and their crystallographic orientations?**

### Hypothesis

The CV measurements cover a range of scan rates, and the distribution of
scan-rate categories differs across material--orientation combinations.

Scan rate is treated as an experimental-condition variable rather than
as a direct measure of electrochemical performance.

------------------------------------------------------------------------

# 5. Data Extraction

The echemdb metadata were stored as structured descriptors. They were
converted into standard Python dictionaries using:

``` python
metadata = entry.metadata["echemdb"].to_builtin()
```

Relevant metadata were extracted from:

-   `system`
-   `electrodes`
-   `electrolyte`
-   `figureDescription`
-   `source`

The working electrode was identified from the electrode list:

``` python
we = next(
    electrode
    for electrode in system["electrodes"]
    if electrode["name"] == "WE"
)
```

The extraction process collected information including:

-   entry identifier
-   electrode material
-   electrode type
-   crystallographic orientation
-   reference electrode
-   counter electrode
-   measurement type
-   scan rate
-   potential metadata
-   current metadata
-   electrolyte information
-   source/citation information
-   publication year
-   DOI
-   figure and curve identifiers

------------------------------------------------------------------------

# 6. Extraction of Digitized CV Curves

In addition to metadata, the project extracted the digitized CV curves
associated with the selected entries.

For each echemdb entry:

``` python
df_entry = entry.df.copy()
```

The digitized data were inspected for either:

-   `j` = current density
-   `I` = current

The resulting point-level table contains:

-   `entry_id`
-   `t`
-   `E`
-   `j`
-   `I`
-   `cycle`
-   `signal_type`

Some records contain current density, while others contain absolute
current.

The project therefore preserves the original signal representation
instead of incorrectly converting or comparing incompatible values.

Final point-level dataset:

**704,968 CV points across 207 measurements.**

------------------------------------------------------------------------

# 7. Data Cleaning and Polishing

The raw extracted metadata required cleaning before relational database
construction.

## 7.1 Standardizing text fields

Text values were stripped and standardized where appropriate.

Electrolyte components were converted into a canonical representation,
for example:

``` text
HClO4 + water
```

rather than retaining inconsistent delimiter formatting.

------------------------------------------------------------------------

## 7.2 Cleaning concentration metadata

Some entries contained partially populated concentration descriptions
such as:

``` text
CsF: 0.1 mol / l; HClO4: None mol / l
```

Invalid `None` concentration fragments were removed.

``` python
def format_concentrations(value):
    if pd.isna(value):
        return pd.NA

    parts = str(value).split(";")
    cleaned = []

    for part in parts:
        part = part.strip()

        if ": None" in part:
            continue

        if part:
            cleaned.append(part)

    if not cleaned:
        return pd.NA

    return "; ".join(cleaned)
```

------------------------------------------------------------------------

## 7.3 Cleaning electrolyte conditions

Electrolyte components were standardized into a canonical condition:

``` python
df_master["electrolyte_condition"] = (
    df_master["electrolyte_components"]
    .fillna("Unknown")
    .apply(
        lambda x: " + ".join(
            part.strip()
            for part in str(x).split(";")
            if part.strip()
        )
    )
)
```

This creates a reproducible textual representation that can be used for
lookup-table construction.

------------------------------------------------------------------------

# 8. Numerical-to-Categorical Transformation

One requirement of the project was to demonstrate transformation of a
numerical variable into a categorical variable.

The numerical variable selected was:

``` text
scan_rate_value
```

The scan rates were grouped into three categories:

  Category   Definition
  ---------- ----------------------
  Low        ≤ 10 mV/s
  Medium     \> 10 and ≤ 50 mV/s
  High       \> 50 and ≤ 100 mV/s

The resulting categorical field is:

``` text
scan_rate_category
```

This transformation allows SQL queries to compare experimental-condition
groups rather than only individual numerical values.

For the selected dataset:

  Scan-rate category     Measurements
  -------------------- --------------
  Low                              65
  Medium                          131
  High                             11

The original numerical `scan_rate_value` is retained, so the
transformation is non-destructive.

------------------------------------------------------------------------

# 9. Master Measurement Table

A cleaned master DataFrame was constructed before normalization.

The final master representation included fields such as:

``` text
measurement_id
entry_id
material
electrode_type
orientation
reference_electrode
reference_material
counter_electrode
measurement_type
scan_rate_value
scan_rate_unit
scan_rate_category
potential_name
potential_unit
potential_reference
current_name
current_unit
electrolyte_type
electrolyte_components
solvent
gas
concentrations
citation_key
doi_url
figure
curve
publication_year
electrolyte_condition
concentration_value
concentration_unit
```

A sequential:

``` text
measurement_id = 1 ... 207
```

was added as the internal primary identifier for the measurement
records.

------------------------------------------------------------------------

# 10. Relational Database Design

The master dataset was normalized into six related tables.

## Tables

### 1. `materials`

Lookup table for electrode materials.

``` text
material_id
material_name
```

Rows:

**2**

------------------------------------------------------------------------

### 2. `orientations`

Lookup table for crystallographic orientations.

``` text
orientation_id
orientation_name
```

Rows:

**3**

------------------------------------------------------------------------

### 3. `sources`

Stores publication/citation information.

``` text
source_id
citation_key
doi_url
publication_year
```

Rows:

**53**

------------------------------------------------------------------------

### 4. `electrolytes`

Stores unique electrolyte conditions.

``` text
electrolyte_id
electrolyte_condition_key
electrolyte_components_canonical
electrolyte_type
electrolyte_condition
solvent
gas
concentrations
concentrations_canonical
```

Rows:

**109**

------------------------------------------------------------------------

### 5. `measurements`

Central metadata table linking the lookup tables.

It contains:

``` text
measurement_id
entry_id
material_id
orientation_id
electrolyte_id
source_id
electrode_type
reference_electrode
reference_electrode_family
reference_electrode_detail
reference_material
counter_electrode
measurement_type
scan_rate_value
scan_rate_unit
scan_rate_category
potential_name
potential_unit
potential_reference
current_name
current_unit
```

Rows:

**207**

------------------------------------------------------------------------

### 6. `cv_points`

Point-level digitized cyclic voltammetry data.

``` text
point_id
measurement_id
entry_id
t
E
j
I
cycle
signal_type
```

Rows:

**704,968**

------------------------------------------------------------------------

# 11. Lookup Tables and Foreign Keys

Categorical information with repeated values was separated into lookup
tables.

For example:

Instead of storing:

``` text
material = Pt
material = Au
material = Pt
material = Au
...
```

in every measurement row, the database stores:

``` text
materials
-----------
material_id | material_name
1           | Au
2           | Pt
```

and references the corresponding record through:

``` text
measurements.material_id
```

The same approach was used for:

-   materials
-   crystallographic orientations
-   sources
-   electrolyte conditions

This reduces duplication and demonstrates relational database design.

------------------------------------------------------------------------

# 12. Entity Relationship Structure

The final relational structure is:

``` text
materials (1)
       |
       | 1-to-many
       v
measurements (many)
       ^
       |
orientations (1)


sources (1)
       |
       | 1-to-many
       v
measurements (many)


electrolytes (1)
       |
       | 1-to-many
       v
measurements (many)


measurements (1)
       |
       | 1-to-many
       v
cv_points (many)
```

### Primary keys

``` text
materials.material_id
orientations.orientation_id
sources.source_id
electrolytes.electrolyte_id
measurements.measurement_id
cv_points.point_id
```

### Foreign keys

``` text
measurements.material_id
    → materials.material_id

measurements.orientation_id
    → orientations.orientation_id

measurements.electrolyte_id
    → electrolytes.electrolyte_id

measurements.source_id
    → sources.source_id

cv_points.measurement_id
    → measurements.measurement_id

cv_points.entry_id
    → measurements.entry_id
```

`measurements.entry_id` is also defined as `UNIQUE`.

------------------------------------------------------------------------

# 13. CSV Generation

Each normalized table was exported as an individual CSV file.

``` python
from pathlib import Path

data_dir = Path("data/clean")
data_dir.mkdir(parents=True, exist_ok=True)

materials.to_csv(data_dir / "materials.csv", index=False)
orientations.to_csv(data_dir / "orientations.csv", index=False)
sources.to_csv(data_dir / "sources.csv", index=False)
electrolytes.to_csv(data_dir / "electrolytes.csv", index=False)
measurements.to_csv(data_dir / "measurements.csv", index=False)
cv_points.to_csv(data_dir / "cv_points.csv", index=False)
```

Final CSV files:

``` text
data/
└── clean/
    ├── materials.csv
    ├── orientations.csv
    ├── sources.csv
    ├── electrolytes.csv
    ├── measurements.csv
    └── cv_points.csv
```

CSV is intentionally retained as the interchange format. The commas are
field separators and are not evidence of a damaged file.

------------------------------------------------------------------------

# 14. SQLite Database Creation

The final SQLite database is:

``` text
database/electrochemistry.db
```

The database was created from the cleaned CSV tables using the final SQL
schema.

Foreign-key enforcement is enabled per SQLite connection:

``` python
connection.execute("PRAGMA foreign_keys = ON;")
```

Verification:

``` python
connection.execute(
    "PRAGMA foreign_keys;"
).fetchone()[0]
```

Expected result:

``` text
1
```

------------------------------------------------------------------------

# 15. SQLite Schema

The database schema is stored in:

``` text
sql/schema.sql
```

The schema begins with:

``` sql
PRAGMA foreign_keys = ON;
```

and defines six tables:

``` sql
CREATE TABLE materials (...);
CREATE TABLE orientations (...);
CREATE TABLE sources (...);
CREATE TABLE electrolytes (...);
CREATE TABLE measurements (...);
CREATE TABLE cv_points (...);
```

The central design principle is that the four metadata/lookup tables
feed the `measurements` table, while each measurement can contain many
digitized CV points.

------------------------------------------------------------------------

# 16. Database Loading

The tables were loaded in foreign-key order:

1.  `materials`
2.  `orientations`
3.  `sources`
4.  `electrolytes`
5.  `measurements`
6.  `cv_points`

This ordering ensures that referenced parent records exist before
dependent records are inserted.

The final database contains:

  Table               Rows
  -------------- ---------
  materials              2
  orientations           3
  sources               53
  electrolytes         109
  measurements         207
  cv_points        704,968

------------------------------------------------------------------------

# 17. SQL Analysis

SQL queries are stored in:

``` text
sql/queries.sql
```

The project contains more than the minimum five analytical queries and
demonstrates:

-   `JOIN`
-   `GROUP BY`
-   `HAVING`
-   aggregate functions
-   subqueries
-   `COALESCE`
-   data-quality checks

------------------------------------------------------------------------

## Query 1 --- Material and Orientation Distribution

``` sql
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
```

Purpose:

Determine how the selected CV measurements are distributed across
electrode material and crystallographic orientation.

------------------------------------------------------------------------

## Query 2 --- Electrolyte Environments

``` sql
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
```

Purpose:

Explore the electrolyte environments represented in the selected
literature.

------------------------------------------------------------------------

## Query 3 --- Scan-Rate Statistics

``` sql
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
```

Purpose:

Compare reported scan-rate statistics between Pt and Au records.

------------------------------------------------------------------------

## Query 4 --- Scan-Rate Categories

``` sql
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
```

Purpose:

Investigate how experimental scan-rate categories vary across
material--orientation groups.

------------------------------------------------------------------------

## Query 5 --- Groups with at Least 10 Measurements

``` sql
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
```

Purpose:

Demonstrate `HAVING` and identify sufficiently represented
material--orientation groups.

------------------------------------------------------------------------

## Query 6 --- Above-Average Scan Rates

``` sql
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
```

Purpose:

Demonstrate a subquery and identify measurements with scan rates above
the overall dataset average.

------------------------------------------------------------------------

## Query 7 --- Reference Electrode Usage

``` sql
SELECT
    mat.material_name,
    COALESCE(
        me.reference_electrode_family,
        'Unknown'
    ) AS reference_family,
    COUNT(*) AS measurement_count
FROM measurements AS me
JOIN materials AS mat
    ON me.material_id = mat.material_id
GROUP BY
    mat.material_name,
    COALESCE(
        me.reference_electrode_family,
        'Unknown'
    )
ORDER BY
    mat.material_name,
    measurement_count DESC;
```

Purpose:

Investigate the diversity and frequency of reference-electrode metadata.

------------------------------------------------------------------------

## Query 8 --- Current-Unit Data-Quality Check

``` sql
SELECT
    current_unit,
    COUNT(*) AS measurement_count
FROM measurements
GROUP BY current_unit
ORDER BY measurement_count DESC;
```

Purpose:

Identify heterogeneous current units before attempting quantitative
comparisons.

------------------------------------------------------------------------

# 18. Python Analysis

SQL query results were imported into Pandas for further analysis and
visualization.

Example:

``` python
query_scan_rate = """
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
    me.scan_rate_category;
"""

scan_rate_data = pd.read_sql_query(
    query_scan_rate,
    connection
)
```

This creates a reproducible pipeline from:

``` text
SQLite → SQL → Pandas → Visualization
```

------------------------------------------------------------------------

# 19. Visualization 1 --- Material and Orientation Distribution

The first visualization compares the number of measurements across Pt/Au
and the three crystallographic orientations.

``` python
plot_data = material_orientation.pivot(
    index="orientation_name",
    columns="material_name",
    values="measurement_count"
)

ax = plot_data.plot(
    kind="bar",
    figsize=(9, 6)
)

ax.set_xlabel("Crystallographic orientation")
ax.set_ylabel("Number of CV measurements")
ax.set_title(
    "Distribution of Pt and Au Single-Crystal CV Measurements"
)

plt.xticks(rotation=0)
plt.legend(title="Electrode material")
plt.tight_layout()
plt.show()
```

The visualization supports the first research question by making the
uneven representation of material--orientation combinations immediately
visible.

------------------------------------------------------------------------

# 20. Visualization 2 --- Scan-Rate Categories

The second visualization compares scan-rate categories across material
and orientation.

``` python
g = sns.catplot(
    data=scan_rate_data,
    x="orientation_name",
    y="measurement_count",
    hue="scan_rate_category",
    col="material_name",
    kind="bar",
    errorbar=None,
    height=5,
    aspect=1.0
)

g.set_axis_labels(
    "Crystallographic orientation",
    "Number of CV measurements"
)

g.set_titles("{col_name}")

g.figure.subplots_adjust(top=0.82)

g.figure.suptitle(
    "Scan-Rate Categories Across Pt and Au Single-Crystal CV Measurements"
)

plt.show()
```

This visualization supports the second research question.

------------------------------------------------------------------------

# 21. Results and Interpretation

## Research Question 1

The 207 selected CV measurements are not evenly distributed across Pt
and Au or across the three crystallographic orientations.

Some material--orientation combinations are substantially more
represented than others.

This supports the descriptive hypothesis that the selected literature
records are unevenly distributed across crystallographic orientations.

However, measurement frequency should **not** be interpreted as:

-   intrinsic electrochemical activity;
-   scientific importance;
-   material quality;
-   catalytic superiority.

The distribution reflects the literature represented in echemdb and can
be affected by publication history, research interests, experimental
availability, and data availability.

------------------------------------------------------------------------

## Research Question 2

The selected measurements cover a range of CV scan rates, and the
distribution of scan-rate categories varies across material--orientation
combinations.

This supports the hypothesis that the experimental conditions
represented in the database are not uniform.

Scan rate is interpreted as an experimental-condition variable rather
than as a direct measure of electrochemical performance.

------------------------------------------------------------------------

# 22. Data-Quality Assessment

A major feature of this project is that data quality is treated as part
of the analysis rather than as an afterthought.

## Current metadata

The current-related metadata are heterogeneous.

Some measurements report:

-   current density;
-   absolute current;
-   different current units;
-   different formatting conventions.

Several records also contain unusual current-unit metadata that require
further validation.

Therefore, raw current values are **not directly comparable across all
records** without additional normalization and scientific validation.

For this reason, the project focuses on robust metadata-level
comparisons rather than making unsupported quantitative claims about
intrinsic electrochemical activity.

------------------------------------------------------------------------

## Missing values

Missing metadata were retained when the source did not provide the
corresponding information.

Examples include:

-   reference electrode information;
-   reference material;
-   counter electrode;
-   potential reference;
-   gas;
-   electrolyte concentration.

Missing scientific metadata were not arbitrarily imputed because doing
so could introduce information that was not present in the source
record.

------------------------------------------------------------------------

# 23. Database Validation

The final database was checked using SQLite integrity and foreign-key
validation.

``` python
tables = [
    "materials",
    "orientations",
    "sources",
    "electrolytes",
    "measurements",
    "cv_points"
]

for table in tables:
    count = connection.execute(
        f"SELECT COUNT(*) FROM {table}"
    ).fetchone()[0]

    print(f"{table:15s}: {count:,}")

fk_errors = connection.execute(
    "PRAGMA foreign_key_check;"
).fetchall()

integrity = connection.execute(
    "PRAGMA integrity_check;"
).fetchone()[0]
```

Expected final validation:

``` text
materials      : 2
orientations   : 3
sources        : 53
electrolytes   : 109
measurements   : 207
cv_points      : 704,968

Foreign-key errors: 0
Database integrity: ok
```

Additional structural checks confirmed:

-   measurement IDs are unique;
-   entry IDs are unique;
-   all measurement foreign keys are valid;
-   all 207 measurements are represented in the CV point table;
-   all CV points map to a valid measurement.

------------------------------------------------------------------------

# 24. Project Structure

The completed project follows a reproducible data-science workflow:

``` text
Project 1/
│
├── README.md
│
├── EDA_and_processing.ipynb
├── Hypotheses_and_visualizations.ipynb
│
├── data/
│   └── clean/
│       ├── materials.csv
│       ├── orientations.csv
│       ├── sources.csv
│       ├── electrolytes.csv
│       ├── measurements.csv
│       └── cv_points.csv
│
├── database/
│   └── electrochemistry.db
│
└── sql/
    ├── schema.sql
    └── queries.sql
```

The notebooks contain the extraction, cleaning, transformation,
exploratory analysis, hypotheses, SQL analysis, and visualization
workflow.

The SQL directory contains the database schema and analytical queries.

The `data/clean` directory contains the normalized CSV tables used to
populate SQLite.

------------------------------------------------------------------------

# 25. Reproducibility Workflow

A simplified reproduction of the project follows these stages:

### Step 1 --- Acquire

Connect to echemdb:

``` python
db = Echemdb.from_remote(version="0.9.2")
```

### Step 2 --- Filter

Select:

``` text
Pt + Au
single crystal
orientations 100 + 110 + 111
```

### Step 3 --- Extract

Extract metadata and digitized CV curves.

### Step 4 --- Clean

Standardize:

-   text;
-   electrolyte conditions;
-   concentrations;
-   identifiers;
-   metadata fields.

### Step 5 --- Transform

Create:

``` text
scan_rate_category
electrolyte_condition
concentration_value
concentration_unit
measurement_id
```

### Step 6 --- Normalize

Generate:

``` text
materials
orientations
sources
electrolytes
measurements
cv_points
```

### Step 7 --- Export

Write each table to CSV.

### Step 8 --- Create SQLite database

Execute:

``` text
sql/schema.sql
```

### Step 9 --- Load data

Import the six CSV files in foreign-key order.

### Step 10 --- Validate

Run:

``` sql
PRAGMA foreign_key_check;
PRAGMA integrity_check;
```

### Step 11 --- Analyze

Run the SQL queries in:

``` text
sql/queries.sql
```

### Step 12 --- Visualize

Use Pandas, Matplotlib, and Seaborn.

### Step 13 --- Interpret

Answer the research questions while accounting for data quality and
literature bias.

------------------------------------------------------------------------

# 26. Technologies Used

  -----------------------------------------------------------------------
  Technology                          Purpose
  ----------------------------------- -----------------------------------
  Python                              Data extraction, transformation,
                                      validation

  Pandas                              DataFrames, cleaning, analysis

  echemdb Python interface            Dataset acquisition and
                                      scientific-data extraction

  SQLite                              Relational database

  SQL                                 Database querying and analysis

  DB Browser for SQLite               Database inspection and SQL
                                      execution

  Matplotlib                          Visualization

  Seaborn                             Statistical/categorical
                                      visualization

  Jupyter Notebook                    Reproducible analysis

  Git/GitHub                          Version control and portfolio
                                      presentation
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 27. Skills Demonstrated

This project demonstrates practical skills in:

### Data acquisition

-   working with a scientific data API/library;
-   selecting a reproducible dataset version;
-   programmatic filtering.

### Data extraction

-   navigating nested metadata;
-   extracting structured experimental information;
-   extracting digitized measurement data.

### Data cleaning

-   handling missing metadata;
-   standardizing text;
-   cleaning concentration information;
-   canonicalizing electrolyte conditions;
-   preserving scientifically meaningful missing values.

### Data transformation

-   numerical-to-categorical transformation;
-   scan-rate categorization;
-   identifier generation;
-   metadata normalization.

### Relational database design

-   primary keys;
-   foreign keys;
-   lookup tables;
-   normalization;
-   one-to-many relationships;
-   referential integrity.

### SQL

-   `SELECT`;
-   `JOIN`;
-   `GROUP BY`;
-   `HAVING`;
-   `COUNT`;
-   `AVG`;
-   `MIN`;
-   `MAX`;
-   `COALESCE`;
-   subqueries;
-   quality-control queries.

### Data visualization

-   categorical comparison;
-   grouped bar charts;
-   scan-rate distributions;
-   interpretation of experimental metadata.

### Scientific data analysis

-   defining research questions;
-   formulating hypotheses;
-   distinguishing descriptive patterns from scientific claims;
-   identifying heterogeneous metadata;
-   avoiding unsupported comparisons.

------------------------------------------------------------------------

# 28. Limitations

Several limitations should be considered.

### Literature representation

The 207 measurements represent the selected records available in
echemdb, not the complete worldwide literature on Pt and Au
single-crystal CV measurements.

### Unequal representation

Some material--orientation combinations contain substantially more
measurements than others.

### Heterogeneous experimental conditions

The measurements originate from different studies and may use different:

-   electrolytes;
-   reference electrodes;
-   counter electrodes;
-   current units;
-   potential references;
-   scan rates;
-   experimental conventions.

### Current normalization

A rigorous comparison of electrochemical current would require
additional scientific validation of:

-   current vs. current-density fields;
-   electrode area;
-   units;
-   reference-electrode conversions;
-   potential conventions;
-   experimental geometry.

That analysis is intentionally outside the scope of the current project.

### Digitized data

The CV curves are digitized representations of published figures and
therefore may not have the same precision as the original raw
experimental datasets.

------------------------------------------------------------------------

# 29. Future Improvements

The database can be extended in several directions.

## More detailed electrolyte normalization

Instead of storing electrolyte components as a canonical text field,
future versions could create:

``` text
electrolyte_components
electrolyte_component_map
```

This would enable SQL-level analysis of individual ions and
concentrations.

## Electrochemical unit normalization

A future version could systematically normalize:

-   current;
-   current density;
-   potential;
-   reference electrodes;
-   concentration units.

## Curve-level analysis

The `cv_points` table provides a foundation for:

-   peak detection;
-   charge estimation;
-   scan-rate dependence;
-   cycle comparison;
-   feature extraction;
-   machine-learning applications.

## Automated data-quality checks

Future pipelines could automatically flag:

-   inconsistent units;
-   missing electrode areas;
-   impossible numerical values;
-   unusual metadata;
-   incomplete reference-electrode information.

## Dashboard

The SQL database could support an interactive dashboard showing:

-   measurement distributions;
-   electrolyte environments;
-   scan rates;
-   literature coverage;
-   selected CV curves.

------------------------------------------------------------------------

# 30. Conclusion

This project demonstrates a complete scientific data pipeline:

``` text
echemdb
   ↓
Dataset selection
   ↓
Python extraction
   ↓
Data cleaning and polishing
   ↓
Numerical → categorical transformation
   ↓
Relational / lookup-table generation
   ↓
CSV export
   ↓
SQLite schema creation
   ↓
Database loading
   ↓
SQL queries/analysis
   ↓
Python/Pandas analysis
   ↓
Visualization
   ↓
Hypothesis evaluation
   ↓
Data-quality assessment
   ↓
Scientific interpretation/Insight
```

The final database contains:

``` text
2 materials
3 orientations
53 sources
109 electrolyte conditions
207 measurements
704,968 digitized CV points
```

The project shows how a domain-specific scientific dataset can be
converted into a structured relational database and analyzed using
modern data-science tools.

Most importantly, it demonstrates that **data engineering, SQL,
visualization, and scientific reasoning must be combined** when working
with heterogeneous experimental datasets.

------------------------------------------------------------------------

## Author

**Dr. Theophilus Kobina Sarpey**

Scientific background: Electrocatalysis, electrochemistry, materials
science, cyclic voltammetry, EIS, and nanostructured electrodes.

Current focus: Python, SQL, data analysis, scientific data engineering,
and machine learning.
