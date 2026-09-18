"""Calibration summary (GATE 5, TASK 5).

Builds on ``evaluate.calibration_table`` without changing it.  Reports
overall bias (mean predicted minus mean observed), worst-bin deviation,
and sample-size sufficiency per bin.  Flags over/underconfidence
directionally.  No recalibration is performed (explicitly out of scope).
"""

from __future__ import annotations

MIN_BIN_N = 10


def summarize_calibration(table: list[dict]) -> dict:
    """Summarize one calibration table (list of bin dicts)."""
    total = sum(b["n"] for b in table)
    weighted_p = sum(b["mean_p"] * b["n"] for b in table
                     if b["n"] and b["mean_p"] is not None)
    weighted_y = sum(b["mean_y"] * b["n"] for b in table
                     if b["n"] and b["mean_y"] is not None)
    counted = sum(b["n"] for b in table if b["n"])
    bias = (weighted_p - weighted_y) / counted if counted else None
    bins = []
    for entry in table:
        deviation = (None if entry["n"] == 0 or entry["mean_p"] is None
                     or entry["mean_y"] is None
                     else entry["mean_p"] - entry["mean_y"])
        bins.append({
            "bin": entry["bin"],
            "n": entry["n"],
            "deviation": deviation,
            "sufficient_n": entry["n"] >= MIN_BIN_N,
            "direction": ("overconfident" if deviation is not None
                          and deviation > 0
                          else "underconfident" if deviation is not None
                          and deviation < 0 else "unknown"),
        })
    measurable = [b["deviation"] for b in bins if b["deviation"] is not None]
    return {
        "total_n": total,
        "overall_bias": bias,
        "overall_direction": ("overconfident" if bias is not None and bias > 0
                              else "underconfident" if bias is not None
                              and bias < 0 else "unknown"),
        "worst_bin_deviation": (max(measurable, key=abs)
                                if measurable else None),
        "sufficient_sample": total >= MIN_BIN_N,
        "bins": bins,
    }
