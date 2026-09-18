"""Point-in-time ML feature pipeline (GATE 17).

Sidecar only.  The Spring Boot AdaptiveEngine remains authoritative; this
package never writes learner state, never touches scoring/mastery/XP, and
never modifies the backend or the database.

Pipeline stages:

1. :mod:`mlrag.feature_pipeline.extract` — read-only extraction from MySQL
   (SELECT-only, explicit columns, no PII; raw user IDs are hashed to
   surrogate learner keys at the boundary).
2. :mod:`mlrag.feature_pipeline.builder` — strict prediction-time
   (``< T``) feature construction for frozen feature version ``f1``.
3. :mod:`mlrag.feature_pipeline.contract` — frozen schema, allowlists,
   validation, and the leakage blocklist.
4. :mod:`mlrag.feature_pipeline.snapshot` — live-snapshot runner used for
   Gate 17 verification (statistics, parity, performance).

No model is trained here.  No synthetic data is created here.
"""

from .contract import (
    DATA_VERSION_SCHEME,
    FEATURE_COLUMNS,
    FEATURE_GROUPS,
    FEATURE_VERSION,
    TARGET_COLUMN,
)

__all__ = [
    "DATA_VERSION_SCHEME",
    "FEATURE_COLUMNS",
    "FEATURE_GROUPS",
    "FEATURE_VERSION",
    "TARGET_COLUMN",
]
