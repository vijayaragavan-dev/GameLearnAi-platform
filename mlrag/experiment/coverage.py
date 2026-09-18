"""Per-feature coverage reporting (GATE 5, TASK 1).

Read-only introspection over already-built feature rows.  Reports, per
column, total / non-null-finite / missing counts and coverage percentage.
Changes nothing about feature values, definitions, imputation, or splits.
"""

from __future__ import annotations

import math

from .features import FEATURE_COLUMNS


def _is_present(value: object) -> bool:
    if value is None:
        return False
    if isinstance(value, float) and not math.isfinite(value):
        return False
    return True


def feature_coverage(rows: list[dict],
                     columns: tuple[str, ...] = FEATURE_COLUMNS) -> dict:
    """Coverage per column for one row set (dataset or single fold)."""
    total = len(rows)
    report: dict[str, dict[str, float | int]] = {}
    for column in columns:
        present = sum(1 for r in rows if _is_present(r.get(column)))
        missing = total - present
        report[column] = {
            "total": total,
            "non_null": present,
            "missing": missing,
            "coverage_pct": (100.0 * present / total) if total else 0.0,
        }
    return {"columns": report, "n_rows": total}
