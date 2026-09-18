"""Gate 13 signal-guard tests (DESIGN ONLY). Standard library only.

Encodes the gap analysis' machine-checkable rules so future collection
work cannot silently violate them: forbidden-feature blocklist,
game-mastery linkage requirement, response-time exclusion from the
current feature schema, recommendation outcome separation, priority
table structure, privacy exclusions.  No database, no services.

Run: python -m unittest mlrag.tests.test_gate13_data_signals -v
"""

from __future__ import annotations

import unittest

from mlrag.contracts.leakage import (POST_ATTEMPT_BLOCKLIST,
                                     validate_feature_names)
from mlrag.experiment.features import FEATURE_COLUMNS
from mlrag.experiment.model import NUMERIC_COLUMNS

#: Signals that must NEVER become pre-event features (Gate 13 §18/§22).
NEVER_FEATURES = frozenset({
    "is_correct", "score", "correct_count", "selected_answer",
    "mastery_score", "recent_accuracy", "recommendation_current",
    "response_time_seconds", "duration_seconds",
    "game_score", "game_difficulty", "xp_awarded",
})

#: PII/surveillance that must never be collected (Gate 13 §22).
NEVER_COLLECT = frozenset({
    "password", "password_hash", "jwt", "refresh_token", "email",
    "location", "keystrokes", "device_id", "raw_client_duration",
})

#: Priority table skeleton asserted structurally (Gate 13 §21).
PRIORITY_LEVELS = frozenset({"P0", "P1", "P2", "P3"})


class NeverFeatureTest(unittest.TestCase):
    def test_blocklist_contains_never_features(self):
        for name in NEVER_FEATURES:
            self.assertIn(name, POST_ATTEMPT_BLOCKLIST, msg=name)

    def test_current_schema_excludes_them(self):
        for name in NEVER_FEATURES:
            self.assertNotIn(name, FEATURE_COLUMNS, msg=name)
            self.assertNotIn(name, NUMERIC_COLUMNS, msg=name)

    def test_response_time_historically_impossible(self):
        # f1 has no per-question timing column at all: NULL history
        # cannot leak in.  (days_since_last_attempt is an event-gap
        # feature, not think time, and is allowed.)
        import re
        timing = [c for c in FEATURE_COLUMNS
                  if re.search(r"response_time|duration|think_time", c)]
        self.assertEqual(timing, [])

    def test_blocked_names_rejected_as_features(self):
        with self.assertRaises(Exception):
            validate_feature_names(["topic_id", "is_correct"])
        with self.assertRaises(Exception):
            validate_feature_names(["topic_id", "response_time_seconds"])
        with self.assertRaises(Exception):
            validate_feature_names(["topic_id", "game_score"])


class GameMasteryProtectionTest(unittest.TestCase):
    def test_no_game_skill_in_feature_schema(self):
        import re
        game_like = [c for c in FEATURE_COLUMNS
                     if re.search(r"\bgame|combo|_xp\b|^xp_", c)]
        self.assertEqual(game_like, [])


class RecommendationSeparationTest(unittest.TestCase):
    def test_outcome_not_a_feature_name(self):
        for name in ("recommendation_outcome", "recommendation_success",
                     "recommendation_helped"):
            self.assertNotIn(name, FEATURE_COLUMNS)


class PriorityStructureTest(unittest.TestCase):
    def test_priority_levels_complete(self):
        self.assertEqual(PRIORITY_LEVELS, {"P0", "P1", "P2", "P3"})

    def test_privacy_exclusions_named(self):
        for name in NEVER_COLLECT:
            self.assertIsInstance(name, str)
        self.assertIn("password", NEVER_COLLECT)
        self.assertIn("keystrokes", NEVER_COLLECT)


if __name__ == "__main__":
    unittest.main()
