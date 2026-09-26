-- REALM-001: backend-authoritative game compatibility for Aptitude.
-- Only QUESTION-kind games whose mechanics run on pure MCQ content
-- (quiz_battle, speed_run) are enabled. No other game is exposed for
-- this subject; clients must never infer compatibility.

INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '99999999-9999-9999-9999-999999999901', '55555555-5555-5555-5555-555555555501', 'quiz_battle',
    'Aptitude skills are assessed through curated multiple-choice questions, the native content of Quiz Battle.',
    1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '99999999-9999-9999-9999-999999999901');

INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '99999999-9999-9999-9999-999999999902', '55555555-5555-5555-5555-555555555501', 'speed_run',
    'Timed multiple-choice drills fit Speed Run mechanics without extra content fields.',
    2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '99999999-9999-9999-9999-999999999902');
