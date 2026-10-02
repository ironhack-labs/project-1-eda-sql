
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS cv_points;
DROP TABLE IF EXISTS measurements;
DROP TABLE IF EXISTS electrolytes;
DROP TABLE IF EXISTS sources;
DROP TABLE IF EXISTS orientations;
DROP TABLE IF EXISTS materials;

CREATE TABLE materials (
    material_id INTEGER PRIMARY KEY,
    material_name TEXT NOT NULL UNIQUE
);

CREATE TABLE orientations (
    orientation_id INTEGER PRIMARY KEY,
    orientation_name TEXT NOT NULL UNIQUE
);

CREATE TABLE sources (
    source_id INTEGER PRIMARY KEY,
    citation_key TEXT NOT NULL UNIQUE,
    title TEXT,
    journal TEXT,
    publication_year INTEGER,
    doi_url TEXT
);

CREATE TABLE electrolytes (
    electrolyte_id INTEGER PRIMARY KEY,
    electrolyte_type TEXT,
    electrolyte_condition TEXT NOT NULL,
    solvent TEXT,
    gas TEXT,
    concentrations TEXT
);

CREATE TABLE measurements (
    measurement_id INTEGER PRIMARY KEY,
    entry_id TEXT NOT NULL UNIQUE,

    material_id INTEGER NOT NULL,
    orientation_id INTEGER NOT NULL,
    electrolyte_id INTEGER NOT NULL,
    source_id INTEGER NOT NULL,

    electrode_type TEXT,
    reference_electrode TEXT,
    reference_material TEXT,
    counter_electrode TEXT,

    measurement_type TEXT NOT NULL,

    scan_rate_value REAL,
    scan_rate_unit TEXT,
    scan_rate_category TEXT,

    potential_name TEXT,
    potential_unit TEXT,
    potential_reference TEXT,

    current_name TEXT,
    current_unit TEXT,

    FOREIGN KEY (material_id)
        REFERENCES materials(material_id),

    FOREIGN KEY (orientation_id)
        REFERENCES orientations(orientation_id),

    FOREIGN KEY (electrolyte_id)
        REFERENCES electrolytes(electrolyte_id),

    FOREIGN KEY (source_id)
        REFERENCES sources(source_id)
);

CREATE TABLE cv_points (
    point_id INTEGER PRIMARY KEY AUTOINCREMENT,

    measurement_id INTEGER NOT NULL,
    entry_id TEXT NOT NULL,

    t REAL NOT NULL,
    E REAL NOT NULL,

    j REAL,
    I REAL,
    cycle INTEGER,

    signal_type TEXT NOT NULL,

    FOREIGN KEY (measurement_id)
        REFERENCES measurements(measurement_id),

    FOREIGN KEY (entry_id)
        REFERENCES measurements(entry_id)
);
