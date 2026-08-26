-- GameLearn AI - deactivate legacy incomplete Programming topics
-- Corrective migration for Phase 10F verification:
-- 5 pre-existing topics (created 2026-08-24 09:07:18) for Programming
--   22222222-2222-2222-2222-222222222201 Introduction to Programming
--   22222222-2222-2222-2222-222222222202 Functions and Modules
--   22222222-2222-2222-2222-222222222203 Data Structures Basics
--   22222222-2222-2222-2222-222222222204 Object Oriented Programming
--   22222222-2222-2222-2222-222222222205 Algorithms and Complexity
-- have is_active=true but 0 lessons/quizzes/questions. They were not created
-- by V12 and are not part of the curated 3-topic demo set (211,212,213).
-- This migration deactivates only those 5 legacy rows, preserving them
-- (no DELETE) so FK history remains intact and they are hidden from
-- active catalog queries (TopicService requires is_active, assessment
-- skips inactive, fallback planner excludes inactive).
-- Uses explicit UUIDs only to avoid affecting the 3 valid V12 topics.
UPDATE topics SET is_active = FALSE, updated_at = CURRENT_TIMESTAMP
WHERE id IN (
  '22222222-2222-2222-2222-222222222201',
  '22222222-2222-2222-2222-222222222202',
  '22222222-2222-2222-2222-222222222203',
  '22222222-2222-2222-2222-222222222204',
  '22222222-2222-2222-2222-222222222205'
);
