"""Reusable functions for the Project 1 pipeline.

The rule from the brief: Python logic lives here, SQL lives in `sql/`, and the
notebooks carry the narrative. When a notebook cell grows past a few lines, or
when you find yourself pasting the same cell twice, it belongs in this file.

Some functions below are **finished** — the mechanical ones, where there is one
obvious right answer and nothing to learn from retyping it. Others are
**`TODO`**: you get the signature, the docstring and the shape of the output,
and the body is yours. Those are the ones where the thinking is the exercise.

Import them into a notebook like this:

    import sys; sys.path.append("..")
    from src.functions import overview, missing_report

Grouped by the notebook that uses them:

    01_eda.ipynb        load_raw, overview, missing_report, duplicate_report,
                        categorical_report
    02_processing.ipynb make_lookup, add_foreign_key, check_fk, export_clean,
                        load_to_sql, table_counts
    03_...ipynb         run_query, plot_bar, save_fig
"""

from __future__ import annotations

import sqlite3
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

# Paths are resolved from this file, so they work whether you run from the repo
# root or from inside notebooks/.
ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
CLEAN = ROOT / "data" / "clean"
SQL = ROOT / "sql"


# ---------------------------------------------------------------------------
# 01_eda.ipynb — explore and question
# ---------------------------------------------------------------------------


def load_raw(filename: str, **kwargs) -> pd.DataFrame:
    """Read one file out of data/raw/, whatever its format.

    Handles .csv, .csv.gz and .xlsx so you do not have to remember which
    reader goes with which extension. Extra keyword arguments are passed
    straight through to the pandas reader, which is how you pass things like
    `sheet_name=` or `parse_dates=`.

    Parameters
    ----------
    filename : str
        Name of the file inside data/raw/, e.g. "listings.csv.gz".
    **kwargs
        Passed to pd.read_csv or pd.read_excel.

    Returns
    -------
    pd.DataFrame
    """
    path = RAW / filename
    if not path.exists():
        available = sorted(p.name for p in RAW.glob("*") if p.name != ".gitkeep")
        raise FileNotFoundError(
            f"{path} not found. Run `python download_data.py <dataset>` first.\n"
            f"Currently in data/raw/: {available or 'nothing'}"
        )
    if path.name.endswith((".xlsx", ".xls")):
        return pd.read_excel(path, **kwargs)
    # pandas infers gzip from the .gz suffix, so one branch covers both.
    return pd.read_csv(path, low_memory=False, **kwargs)


def overview(df: pd.DataFrame) -> pd.DataFrame:
    """One row per column: dtype, non-nulls, nulls, % null, unique values, an example.

    The first thing to run on any new table. It answers "what is in here and
    how broken is it" in a single glance, which is faster than reading .info()
    and .isna().sum() and .nunique() one after another.

    Returns
    -------
    pd.DataFrame
        Indexed by column name, sorted by null percentage descending so the
        problems float to the top.
    """
    summary = pd.DataFrame(
        {
            "dtype": df.dtypes.astype(str),
            "non_null": df.notna().sum(),
            "nulls": df.isna().sum(),
            "pct_null": (df.isna().mean() * 100).round(1),
            "n_unique": df.nunique(dropna=True),
            "example": [
                df[c].dropna().iloc[0] if df[c].notna().any() else None
                for c in df.columns
            ],
        }
    )
    return summary.sort_values("pct_null", ascending=False)


def missing_report(df: pd.DataFrame, threshold: float = 0.0) -> pd.DataFrame:
    """Columns with missing values, worst first.

    Parameters
    ----------
    df : pd.DataFrame
    threshold : float, default 0.0
        Only report columns whose share of missing values is strictly above
        this. Pass 0.5 to see just the columns that are more than half empty.

    Returns
    -------
    pd.DataFrame
        Columns: n_missing, pct_missing.
    """
    share = df.isna().mean()
    report = pd.DataFrame(
        {"n_missing": df.isna().sum(), "pct_missing": (share * 100).round(2)}
    )
    return report[share > threshold].sort_values("pct_missing", ascending=False)


def duplicate_report(df: pd.DataFrame, subset: list[str] | None = None) -> dict:
    """Count duplicate rows, and blank strings that are really missing values.

    The second half matters more than it sounds. `""` and `" "` are not NaN, so
    `isna()` does not see them and `dropna()` does not remove them, and they
    quietly survive all the way into your database as empty-string categories.

    Parameters
    ----------
    df : pd.DataFrame
    subset : list of str, optional
        Consider rows duplicates when these columns match, rather than all
        columns. Use it to check a candidate primary key: pass ["id"] and a
        non-zero count means it is not unique.

    Returns
    -------
    dict
        n_duplicates, pct_duplicates, and blank_strings (a dict of column ->
        count, only for columns that have any).
    """
    dupes = df.duplicated(subset=subset).sum()
    blanks = {}
    for column in df.select_dtypes(include="object").columns:
        count = int(df[column].astype(str).str.strip().eq("").sum())
        if count:
            blanks[column] = count
    return {
        "n_duplicates": int(dupes),
        "pct_duplicates": round(dupes / len(df) * 100, 2) if len(df) else 0.0,
        "blank_strings": blanks,
    }


def categorical_report(df: pd.DataFrame, max_unique: int = 30) -> pd.DataFrame:
    """Find the lookup-table candidates: text columns with few distinct values.

    This is the bridge between notebook 01 and notebook 02. A column with 7
    distinct values across 24,000 rows is a lookup table waiting to happen —
    that is Option A in the brief. A column with 15,000 distinct values across
    15,000 rows is an identifier, not a category.

    Parameters
    ----------
    df : pd.DataFrame
    max_unique : int, default 30
        Report object/category columns with at most this many distinct values.
        Raise it if your categories are genuinely numerous, like country.

    Returns
    -------
    pd.DataFrame
        Columns: n_unique, pct_unique, values (up to the first 10).
        Sorted by n_unique ascending, so the best candidates come first.
    """
    rows = []
    for column in df.select_dtypes(include=["object", "category"]).columns:
        values = df[column].dropna().unique()
        if len(values) <= max_unique:
            rows.append(
                {
                    "column": column,
                    "n_unique": len(values),
                    "pct_unique": round(len(values) / max(len(df), 1) * 100, 3),
                    "values": list(map(str, values[:10])),
                }
            )
    if not rows:
        return pd.DataFrame(columns=["n_unique", "pct_unique", "values"])
    return (
        pd.DataFrame(rows).set_index("column").sort_values("n_unique")
    )


# ---------------------------------------------------------------------------
# 02_processing.ipynb — clean, design, load
# ---------------------------------------------------------------------------


def make_lookup(
    df: pd.DataFrame, column: str, id_name: str | None = None
) -> pd.DataFrame:
    """Turn one categorical column into a lookup table.

    Step 3 of Option A in the brief. Given a column like `room_type` with four
    distinct values, this returns the table that will hold them:

        room_type_id | room_type
        -------------+------------------
                   1 | Entire home/apt
                   2 | Hotel room
                   3 | Private room
                   4 | Shared room

    Parameters
    ----------
    df : pd.DataFrame
        The table the column currently lives in.
    column : str
        The categorical column to extract.
    id_name : str, optional
        Name for the surrogate key. Defaults to f"{column}_id".

    Returns
    -------
    pd.DataFrame
        Two columns — the id and the value — with one row per distinct
        non-null value and no index to worry about.

    Notes
    -----
    Three decisions to make, and they are the reason this is a TODO:

    - **Drop the nulls or keep an "Unknown" row?** If the source column has
      missing values and you drop them, those rows end up with a null foreign
      key. Decide which you want and be able to defend it.
    - **Sort before assigning ids, or not?** Sorting makes the ids stable, so
      re-running the notebook gives the same numbers. Not sorting means they
      shift, which quietly invalidates a database you loaded yesterday.
    - **Start ids at 1 or 0?** Either works. Just be consistent, because
      `add_foreign_key` has to agree with whatever you choose.
    """
    # TODO: implement. Roughly:
    #   1. get the distinct non-null values of df[column]
    #   2. sort them so the ids are reproducible
    #   3. build a DataFrame with an id column and the value column
    #   4. return it with a clean 0..n-1 index (reset_index(drop=True))
    raise NotImplementedError("make_lookup is yours to write - see the docstring")


def add_foreign_key(
    df: pd.DataFrame, lookup: pd.DataFrame, column: str, id_name: str | None = None
) -> pd.DataFrame:
    """Replace a categorical column with the foreign key from its lookup table.

    Step 4 of Option A. The inverse of `make_lookup`: where that one pulled the
    values out, this one puts the keys back in. After this, `df` no longer
    carries the text — it carries an integer that points at the lookup table.

    Parameters
    ----------
    df : pd.DataFrame
        The table to modify. Not mutated; a copy is returned.
    lookup : pd.DataFrame
        The output of `make_lookup` for this column.
    column : str
        The categorical column in `df` to replace.
    id_name : str, optional
        The key column in `lookup`. Defaults to f"{column}_id".

    Returns
    -------
    pd.DataFrame
        A copy of `df` with `column` dropped and `id_name` added.

    Notes
    -----
    A merge is the obvious tool, and there are two traps in it:

    - **Use a left merge.** An inner merge silently drops any row whose value
      is not in the lookup, and you will not notice until your row count is
      wrong. `check_fk` exists to catch exactly that.
    - **Drop the original text column afterwards.** Keeping both is
      denormalised — the whole point of the exercise was to store the label
      once.
    """
    # TODO: implement. Roughly:
    #   1. merge df with lookup on `column`, how="left"
    #   2. drop the original text column
    #   3. return the result
    raise NotImplementedError("add_foreign_key is yours to write - see the docstring")


def check_fk(
    child: pd.DataFrame, parent: pd.DataFrame, fk: str, pk: str | None = None
) -> dict:
    """Check that every foreign key in `child` exists in `parent`.

    Run this on every relationship before you load anything. A dangling
    foreign key is the single most common way this project goes wrong: SQLite
    will happily accept the rows, and then your Wednesday joins drop them
    without a word of warning.

    Parameters
    ----------
    child : pd.DataFrame
        The table holding the foreign key, e.g. listings.
    parent : pd.DataFrame
        The table holding the primary key, e.g. neighbourhoods.
    fk : str
        Foreign-key column name in `child`.
    pk : str, optional
        Primary-key column name in `parent`. Defaults to `fk`.

    Returns
    -------
    dict
        ok (bool), n_null, n_orphans, and up to 10 example orphan values.
        `ok` is True when there are no orphans; nulls are reported separately
        because a nullable FK can be a legitimate design choice.
    """
    pk = pk or fk
    keys = set(parent[pk].dropna().unique())
    values = child[fk]
    orphan_mask = values.notna() & ~values.isin(keys)
    orphans = values[orphan_mask]
    return {
        "ok": bool(orphans.empty),
        "n_null": int(values.isna().sum()),
        "n_orphans": int(len(orphans)),
        "orphan_examples": list(map(str, orphans.unique()[:10])),
    }


def export_clean(tables: dict[str, pd.DataFrame]) -> None:
    """Write one CSV per table into data/clean/.

    Parameters
    ----------
    tables : dict of str -> pd.DataFrame
        Table name (which becomes the filename and the SQL table name) mapped
        to its DataFrame. Use the same dict for `load_to_sql`, so the CSVs and
        the database cannot drift apart.
    """
    CLEAN.mkdir(parents=True, exist_ok=True)
    for name, table in tables.items():
        path = CLEAN / f"{name}.csv"
        table.to_csv(path, index=False)
        print(f"{path.relative_to(ROOT)}: {len(table):,} rows x {table.shape[1]} cols")


def load_to_sql(
    tables: dict[str, pd.DataFrame],
    db_path: str | Path,
    schema_file: str | Path | None = None,
    replace: bool = False,
) -> None:
    """Create the SQLite database and load every table into it.

    Parameters
    ----------
    tables : dict of str -> pd.DataFrame
        **Insertion order matters.** Python dicts keep the order you wrote
        them in, so put the lookup and dimension tables first and the fact
        tables that reference them last. Load a child before its parent and
        the foreign keys point at nothing.
    db_path : str or Path
        Where to create the .db file, e.g. "../data/project.db". It is
        gitignored, because a database is a build artefact.
    schema_file : str or Path, optional
        A .sql file of CREATE TABLE statements to run first. Pass
        "../sql/schema.sql" to have your declared types and FK constraints
        applied rather than letting pandas guess them.
    replace : bool, default False
        False appends into the tables your schema created, which is what you
        want. True drops each table and lets pandas invent the schema — handy
        while iterating, and it throws away your constraints, so do not ship
        with it on.

    Notes
    -----
    Two things worth knowing about SQLite here:

    - Foreign-key enforcement is **off by default**. This function turns it on
      with `PRAGMA foreign_keys = ON`, which means a bad key now raises
      instead of sneaking through. That is why you run `check_fk` first.
    - `if_exists="replace"` really does drop the table. If you re-run this
      cell with `replace=True` after loading, the old rows are gone.
    """
    db_path = Path(db_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    try:
        conn.execute("PRAGMA foreign_keys = ON")
        if schema_file is not None:
            conn.executescript(Path(schema_file).read_text())
            print(f"ran {Path(schema_file).name}")
        for name, table in tables.items():
            table.to_sql(
                name,
                conn,
                if_exists="replace" if replace else "append",
                index=False,
            )
            print(f"loaded {name}: {len(table):,} rows")
        conn.commit()
    finally:
        conn.close()


def table_counts(db_path: str | Path) -> pd.DataFrame:
    """Row count per table in the database. The check that you loaded what you meant to.

    Returns
    -------
    pd.DataFrame
        Columns: table, n_rows. A table showing 0 rows loaded but did not
        insert, which usually means it went in before its parent.
    """
    conn = sqlite3.connect(db_path)
    try:
        names = pd.read_sql(
            "SELECT name FROM sqlite_master WHERE type='table' "
            "AND name NOT LIKE 'sqlite_%' ORDER BY name",
            conn,
        )["name"]
        rows = [
            {
                "table": name,
                "n_rows": pd.read_sql(f"SELECT COUNT(*) AS n FROM {name}", conn)
                .loc[0, "n"],
            }
            for name in names
        ]
    finally:
        conn.close()
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# 03_hypothesis_and_visualization.ipynb — query, visualise, report
# ---------------------------------------------------------------------------


def run_query(sql: str, db_path: str | Path) -> pd.DataFrame:
    """Run one SQL query and get a DataFrame back.

    The bridge from Week 2 Day 4: SQL does the aggregation, pandas and
    matplotlib do the presentation. Keep the query itself in
    `sql/queries.sql` and read it from there, so the notebook shows the
    narrative rather than a wall of triple-quoted strings.

    Parameters
    ----------
    sql : str
        The query. One statement, no trailing semicolon needed.
    db_path : str or Path
        The .db file built in notebook 02.

    Returns
    -------
    pd.DataFrame
    """
    conn = sqlite3.connect(db_path)
    try:
        return pd.read_sql(sql, conn)
    finally:
        conn.close()


def load_query(name: str, queries_file: str | Path | None = None) -> str:
    """Pull one named query out of sql/queries.sql.

    Mark each query in that file with a name comment and this function finds
    it, which keeps every query in one reviewable .sql file instead of
    scattered through notebook cells:

        -- name: price_by_district
        SELECT ...;

    Parameters
    ----------
    name : str
        The name after "-- name:".
    queries_file : str or Path, optional
        Defaults to sql/queries.sql at the repo root.

    Returns
    -------
    str
        The SQL text, ready to hand to `run_query`.
    """
    path = Path(queries_file) if queries_file else SQL / "queries.sql"
    text = path.read_text()
    marker = f"-- name: {name}"
    if marker not in text:
        raise KeyError(f"No query named {name!r} in {path.name}")
    block = text.split(marker, 1)[1]
    # A query runs to its semicolon; the next "-- name:" starts the next one.
    return block.split(";", 1)[0].split("-- name:")[0].strip() + ";"


def plot_bar(
    df: pd.DataFrame,
    x: str,
    y: str,
    title: str,
    ylabel: str | None = None,
    horizontal: bool = True,
    ax: plt.Axes | None = None,
) -> plt.Axes:
    """Bar chart of a query result, with the labelling already done.

    A chart you put on a slide needs a title, axis labels and readable tick
    labels. This does that part so your cells stay about the finding.

    Parameters
    ----------
    df : pd.DataFrame
        A query result, already aggregated. Sort it before passing it in;
        a bar chart in arbitrary order is hard to read.
    x, y : str
        Category column and value column.
    title : str
        Say what the chart shows, not what type of chart it is. "Median price
        per night by district", not "Bar chart of prices".
    ylabel : str, optional
        Defaults to `y`. Worth setting, because "eur_per_night" reads worse
        than "EUR per night".
    horizontal : bool, default True
        Horizontal bars, which keeps long category names legible.
    ax : matplotlib Axes, optional
        Draw into an existing axes, for subplots.

    Returns
    -------
    matplotlib Axes
    """
    if ax is None:
        _, ax = plt.subplots(figsize=(8, max(3, 0.4 * len(df))))
    if horizontal:
        ax.barh(df[x].astype(str), df[y])
        ax.set_xlabel(ylabel or y)
        ax.invert_yaxis()  # biggest at the top, which is how people read it
    else:
        ax.bar(df[x].astype(str), df[y])
        ax.set_ylabel(ylabel or y)
        ax.tick_params(axis="x", rotation=45)
    ax.set_title(title)
    ax.grid(axis="x" if horizontal else "y", alpha=0.3)
    return ax


def plot_trend(
    df: pd.DataFrame,
    x: str,
    y: str,
    title: str,
    group: str | None = None,
    ylabel: str | None = None,
    ax: plt.Axes | None = None,
) -> plt.Axes:
    """Line chart over time, optionally one line per group.

    Parameters
    ----------
    df : pd.DataFrame
        A query result. If `x` is a date, parse it before plotting or the
        axis comes out as unordered strings.
    x, y : str
        Time column and value column.
    title : str
        What the chart shows.
    group : str, optional
        Draw one line per distinct value of this column, with a legend.
    ylabel : str, optional
        Defaults to `y`.
    ax : matplotlib Axes, optional

    Returns
    -------
    matplotlib Axes

    Notes
    -----
    Left as a TODO because the interesting part is the reshape, not the
    plotting. With `group` set you need one series per group: either loop over
    `df.groupby(group)` and call `ax.plot` for each, or pivot the frame so the
    groups become columns. Both work; the pivot is the Pandas II material.
    """
    # TODO: implement.
    #   - no group: one ax.plot(df[x], df[y])
    #   - with group: one line per group, plus ax.legend()
    #   - always set the title, the ylabel and a light grid
    raise NotImplementedError("plot_trend is yours to write - see the docstring")


def save_fig(fig: plt.Figure | plt.Axes, name: str, folder: str | Path = "figures") -> Path:
    """Save a figure as PNG so you can drop it straight into your slides.

    Parameters
    ----------
    fig : matplotlib Figure or Axes
        Either works; an Axes is resolved to its Figure.
    name : str
        Filename without the extension, e.g. "price_by_district".
    folder : str or Path, default "figures"
        Created if missing, relative to the repo root.

    Returns
    -------
    Path
        Where the file was written.
    """
    figure = fig.get_figure() if isinstance(fig, plt.Axes) else fig
    out = ROOT / folder  # an absolute `folder` is used as-is
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"{name}.png"
    figure.savefig(path, dpi=150, bbox_inches="tight")
    shown = path.relative_to(ROOT) if path.is_relative_to(ROOT) else path
    print(f"saved {shown}")
    return path
