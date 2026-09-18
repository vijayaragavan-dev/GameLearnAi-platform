"""Gate 14.3 engagement-deferral guards (DESIGN ONLY). Stdlib only.

Encodes the deferral contract: no lesson/path completion semantics may
enter the feature schema or be assumed present until explicit product
decisions exist.  No database, no services.

Run: python -m unittest mlrag.tests.test_gate14_3_engagement -v
"""

from __future__ import annotations

import unittest

from mlrag.contracts.leakage import validate_feature_names
from mlrag.experiment.features import FEATURE_COLUMNS

#: Completion-style names with NO product semantics behind them.  Any of
#: these appearing in the schema without a Gate 14.3 product decision is
#: a defect this suite must catch.
DEFERRED_COMPLETION_SIGNALS = frozenset({
    "lesson_completed",
    "lesson_started",
    "lesson_viewed",
    "lesson_dwell_seconds",
    "path_node_completed",
    "node_completed",
    "node_transition",
    "current_node_progress",
})

#: Structural signals derivable today from read APIs (no collection).
DERIVABLE_STRUCTURE = frozenset({
    "path_exists",
    "node_order",
    "required_mastery_gate",
    "canonical_lesson_link",
})


class DeferralContractTest(unittest.TestCase):
    def test_no_completion_signals_in_schema(self):
        for name in DEFERRED_COMPLETION_SIGNALS:
            self.assertNotIn(name, FEATURE_COLUMNS, msg=name)

    def test_invented_completion_names_rejected_strict(self):
        with self.assertRaises(Exception):
            validate_feature_names(["topic_id", "lesson_completed"],
                                   strict=True)

    def test_deferral_set_is_nonempty(self):
        # Guards against silently shrinking the deferred surface.
        self.assertGreaterEqual(len(DEFERRED_COMPLETION_SIGNALS), 8)

    def test_derivable_set_needs_no_collection(self):
        for name in DERIVABLE_STRUCTURE:
            self.assertIsInstance(name, str)
        self.assertIn("node_order", DERIVABLE_STRUCTURE)


if __name__ == "__main__":
    unittest.main()
