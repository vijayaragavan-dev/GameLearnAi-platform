-- QA-6B Phase 1: one progress record per learner + topic.
--
-- The progress table (V8) carries only a non-unique lookup index on
-- (user_id, topic_id). The generic learning-progress upsert
-- (PUT /api/v1/progress/{topicId}) relies on a single row per learner and
-- topic for idempotent repeated completion, so enforce it structurally.
-- No application code writes progress rows today and no seed inserts
-- progress rows, therefore no duplicate cleanup is required: the constraint
-- is the final protection against concurrent double-inserts.
--
-- The pre-existing lookup index idx_progress_user_topic is left untouched.

ALTER TABLE progress ADD CONSTRAINT uq_progress_user_topic UNIQUE (user_id, topic_id);
