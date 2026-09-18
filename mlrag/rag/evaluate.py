"""Retrieval quality metrics (GATE 7, PHASE 4).

Pure functions over ranked ID lists and relevance sets.  A metric that
cannot be validly computed (no relevant documents, empty ranking where a
rank is required) returns None ("unavailable") — never a fabricated zero
masquerading as a measurement, never an imputed value.
"""

from __future__ import annotations


def recall_at_k(ranked_ids: list[str], relevant_ids: set[str],
                k: int) -> float | None:
    """Fraction of relevant docs retrieved in the top K."""
    if k <= 0:
        raise ValueError("k must be positive")
    if not relevant_ids:
        return None
    hits = len(set(ranked_ids[:k]) & relevant_ids)
    return hits / len(relevant_ids)


def precision_at_k(ranked_ids: list[str], relevant_ids: set[str],
                   k: int) -> float | None:
    """Fraction of the top K that is relevant (hits / K)."""
    if k <= 0:
        raise ValueError("k must be positive")
    if not relevant_ids:
        return None
    hits = len(set(ranked_ids[:k]) & relevant_ids)
    return hits / k


def reciprocal_rank(ranked_ids: list[str],
                    relevant_ids: set[str]) -> float | None:
    """1 / rank of the first relevant doc; 0.0 when absent; None if no
    relevance defined."""
    if not relevant_ids:
        return None
    for position, doc_id in enumerate(ranked_ids):
        if doc_id in relevant_ids:
            return 1.0 / (position + 1)
    return 0.0


def mean_or_none(values: list[float | None]) -> float | None:
    """Mean over valid entries; None when nothing is valid."""
    valid = [v for v in values if v is not None]
    if not valid:
        return None
    return sum(valid) / len(valid)
