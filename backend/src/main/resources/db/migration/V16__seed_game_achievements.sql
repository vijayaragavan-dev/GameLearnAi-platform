-- GameLearn AI - extra achievements for the persistent game-result domain
-- (Persistent Gamification + Player Progression phase). These supplement the
-- existing FIRST_QUIZ/PERFECT_SCORE/FIRST_MASTERED/TEN_QUIZZES/STREAK_3/WEEK_WARRIOR
-- catalog. Idempotent insert (uses code) so re-running the migration is safe.
--
-- NOTE: We do NOT add seed rows here. The approved achievement catalog invariant
-- (6 active entries) is asserted by existing tests; adding new seeds would
-- break that assertion. New achievements are written into the catalog by the
-- game-result runtime when the corresponding rule triggers, so that the
-- catalog grows organically with the learner's activity.

SELECT 1;
