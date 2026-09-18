"""Deterministic, versioned ML dataset layer (GATE 18).

Consumes Gate 17 feature rows from :mod:`mlrag.feature_pipeline` (the
authoritative feature-generation pipeline — never duplicated here, never
the old ``mlrag.experiment`` code) and produces a dataset representation
suitable for later training/evaluation.

Stages:

1. :mod:`mlrag.dataset.contract` — versioned dataset contract (``d1`` over
   frozen ``f1``), deterministic row identity, schema validation, and the
   prohibited-content list for persisted artifacts.
2. :mod:`mlrag.dataset.build` — dataset construction (one row per eligible
   question attempt, NULLs preserved, no imputation, target separated) and
   the deterministic dataset fingerprint.
3. :mod:`mlrag.dataset.split` — deterministic learner-aware + time-aware
   split mechanism (``user_aware_time_aware`` vocabulary reused from
   ``mlrag.contracts.evaluation``; random row splits prohibited).
4. :mod:`mlrag.dataset.quality` — data-quality audit, missingness analysis,
   target quality, duplicate/identity audit, PII scan, Gate-5 readiness
   evaluation.
5. :mod:`mlrag.dataset.snapshot` — live-snapshot runner (read-only MySQL).

This gate never trains, tunes, promotes, or integrates any model.
"""

from .contract import (
    DATASET_VERSION,
    FEATURE_VERSION,
    TARGET_COLUMN,
)

__all__ = [
    "DATASET_VERSION",
    "FEATURE_VERSION",
    "TARGET_COLUMN",
]
