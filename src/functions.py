"""Your reusable functions live here.

The rule from the brief: Python logic goes in `.py` files, SQL goes in `.sql`
files, and the notebooks hold the narrative. The moment a cell grows past a few
lines, or you find yourself pasting it a second time, move it here and call it
from the notebook.

To use this module from a notebook in `notebooks/`:

    import sys
    sys.path.append("..")
    from src.functions import *

The stubs below are suggestions — the kind of thing that is usually worth
writing for a project like this. Rename them, change the signatures, add your
own, delete the ones you do not need. This is a starting point, not an
interface you have to implement.
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
CLEAN = ROOT / "data" / "clean"
DB = ROOT / "data" / "project.db"


# --- Exploring (notebook 01) -----------------------------------------------

def load_raw(filename):
    """Read a file from data/raw/ into a DataFrame."""
    pass


def overview(df):
    """Summarise a DataFrame one row per column: dtype, nulls, distinct values."""
    pass


# --- Building the database (notebook 02) -----------------------------------

def make_lookup(df, column):
    """Turn a repeated categorical column into its own table with an id."""
    pass


def add_foreign_key(df, lookup, column):
    """Replace a categorical column with the foreign key pointing at its lookup."""
    pass


def check_fk(child, parent, fk, pk):
    """Check every foreign key value exists in the parent table before you load."""
    pass


def load_to_sql(tables, db_path=DB):
    """Write your tables into the SQLite database."""
    pass


# --- Analysing (notebook 03) -----------------------------------------------

def run_query(sql, db_path=DB):
    """Run a query against the database and return the result as a DataFrame."""
    pass
