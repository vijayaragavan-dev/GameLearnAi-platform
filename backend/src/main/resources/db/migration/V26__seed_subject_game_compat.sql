-- GameLearn AI - Batch 2 / Phase 3: subject/game compatibility seed.
-- Presence of a row = supported combination with an educational rationale;
-- absence = unsupported and never exposed. Deterministic reserved UUID
-- namespace 88888888-...-901..995. Every statement is
-- INSERT...SELECT...WHERE NOT EXISTS (H2 + MySQL portable): re-running
-- never duplicates. Additive only.

-- Programming (111...101): 10 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888901', '11111111-1111-1111-1111-111111111101', 'quiz_battle', 'MCQ battles over programming questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888901');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888902', '11111111-1111-1111-1111-111111111101', 'memory_match', 'Matching programming terms with definitions strengthens language vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888902');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888903', '11111111-1111-1111-1111-111111111101', 'speed_run', 'Timed recall drills reinforce fluent programming knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888903');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888904', '11111111-1111-1111-1111-111111111101', 'boss_battle', 'Mastery challenges over mixed programming questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888904');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888905', '11111111-1111-1111-1111-111111111101', 'snake_and_ladder', 'Board progression driven by programming questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888905');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888906', '11111111-1111-1111-1111-111111111101', 'target_challenge', 'Targeted drills focus practice on programming topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888906');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888907', '11111111-1111-1111-1111-111111111101', 'debug_arena', 'Finding and fixing defects practices real programming debugging skill.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888907');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888908', '11111111-1111-1111-1111-111111111101', 'unlock_code', 'Deriving codes from programming answers practices applied problem solving.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888908');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888909', '11111111-1111-1111-1111-111111111101', 'concept_builder', 'Assembling programs from building blocks practices applied program design.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888909');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888910', '11111111-1111-1111-1111-111111111101', 'puzzle_arena', 'Solving puzzles practices programming problem solving.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888910');

-- Computer Networks (111...102): 9 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888911', '11111111-1111-1111-1111-111111111102', 'quiz_battle', 'MCQ battles over networking questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888911');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888912', '11111111-1111-1111-1111-111111111102', 'memory_match', 'Matching networking terms with definitions strengthens protocol vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888912');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888913', '11111111-1111-1111-1111-111111111102', 'speed_run', 'Timed recall drills reinforce fluent networking knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888913');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888914', '11111111-1111-1111-1111-111111111102', 'boss_battle', 'Mastery challenges over mixed networking questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888914');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888915', '11111111-1111-1111-1111-111111111102', 'snake_and_ladder', 'Board progression driven by networking questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888915');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888916', '11111111-1111-1111-1111-111111111102', 'target_challenge', 'Targeted drills focus practice on networking topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888916');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888917', '11111111-1111-1111-1111-111111111102', 'sequence_master', 'Ordering protocol layers and encapsulation steps practices layered networking procedures.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888917');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888918', '11111111-1111-1111-1111-111111111102', 'mystery_case', 'Investigating connectivity failure cases practices network diagnosis.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888918');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888919', '11111111-1111-1111-1111-111111111102', 'connectivity_lab', 'Hands-on lab tasks practice real network connectivity skills.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888919');

-- DBMS (111...103): 10 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888920', '11111111-1111-1111-1111-111111111103', 'quiz_battle', 'MCQ battles over database questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888920');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888921', '11111111-1111-1111-1111-111111111103', 'memory_match', 'Matching database terms with definitions strengthens SQL vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888921');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888922', '11111111-1111-1111-1111-111111111103', 'speed_run', 'Timed recall drills reinforce fluent database knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888922');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888923', '11111111-1111-1111-1111-111111111103', 'boss_battle', 'Mastery challenges over mixed database questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888923');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888924', '11111111-1111-1111-1111-111111111103', 'snake_and_ladder', 'Board progression driven by database questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888924');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888925', '11111111-1111-1111-1111-111111111103', 'target_challenge', 'Targeted drills focus practice on database topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888925');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888926', '11111111-1111-1111-1111-111111111103', 'concept_builder', 'Assembling schemas from tables and keys practices applied database design.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888926');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888927', '11111111-1111-1111-1111-111111111103', 'drag_drop', 'Sorting attributes into keys and normal forms practices database classification.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888927');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888928', '11111111-1111-1111-1111-111111111103', 'mystery_case', 'Investigating transaction failure cases practices database diagnosis.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888928');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888929', '11111111-1111-1111-1111-111111111103', 'puzzle_arena', 'Solving puzzles practices database problem solving.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888929');

-- Operating Systems (111...104): 8 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888930', '11111111-1111-1111-1111-111111111104', 'quiz_battle', 'MCQ battles over operating system questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888930');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888931', '11111111-1111-1111-1111-111111111104', 'memory_match', 'Matching operating system terms with definitions strengthens systems vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888931');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888932', '11111111-1111-1111-1111-111111111104', 'speed_run', 'Timed recall drills reinforce fluent operating system knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888932');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888933', '11111111-1111-1111-1111-111111111104', 'boss_battle', 'Mastery challenges over mixed operating system questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888933');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888934', '11111111-1111-1111-1111-111111111104', 'snake_and_ladder', 'Board progression driven by operating system questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888934');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888935', '11111111-1111-1111-1111-111111111104', 'target_challenge', 'Targeted drills focus practice on operating system topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888935');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888936', '11111111-1111-1111-1111-111111111104', 'sequence_master', 'Ordering scheduling and synchronization steps practices operating system procedures.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888936');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888937', '11111111-1111-1111-1111-111111111104', 'mystery_case', 'Investigating deadlock and crash cases practices systems diagnosis.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888937');

-- Data Structures (111...105): 8 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888938', '11111111-1111-1111-1111-111111111105', 'quiz_battle', 'MCQ battles over data structure questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888938');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888939', '11111111-1111-1111-1111-111111111105', 'memory_match', 'Matching data structure terms with definitions strengthens algorithm vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888939');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888940', '11111111-1111-1111-1111-111111111105', 'speed_run', 'Timed recall drills reinforce fluent data structure knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888940');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888941', '11111111-1111-1111-1111-111111111105', 'boss_battle', 'Mastery challenges over mixed data structure questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888941');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888942', '11111111-1111-1111-1111-111111111105', 'snake_and_ladder', 'Board progression driven by data structure questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888942');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888943', '11111111-1111-1111-1111-111111111105', 'target_challenge', 'Targeted drills focus practice on data structure topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888943');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888944', '11111111-1111-1111-1111-111111111105', 'drag_drop', 'Sorting elements into structures practices data structure classification.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888944');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888945', '11111111-1111-1111-1111-111111111105', 'puzzle_arena', 'Solving puzzles practices data structure problem solving.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888945');

-- Object Oriented Programming (111...106): 7 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888946', '11111111-1111-1111-1111-111111111106', 'quiz_battle', 'MCQ battles over Java and OOP questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888946');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888947', '11111111-1111-1111-1111-111111111106', 'memory_match', 'Matching OOP terms with definitions strengthens Java vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888947');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888948', '11111111-1111-1111-1111-111111111106', 'speed_run', 'Timed recall drills reinforce fluent OOP knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888948');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888949', '11111111-1111-1111-1111-111111111106', 'boss_battle', 'Mastery challenges over mixed OOP questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888949');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888950', '11111111-1111-1111-1111-111111111106', 'snake_and_ladder', 'Board progression driven by OOP questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888950');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888951', '11111111-1111-1111-1111-111111111106', 'target_challenge', 'Targeted drills focus practice on OOP topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888951');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888952', '11111111-1111-1111-1111-111111111106', 'debug_arena', 'Finding and fixing defects practices real Java debugging skill.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888952');

-- Object Oriented Software Engineering (111...107): 9 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888953', '11111111-1111-1111-1111-111111111107', 'quiz_battle', 'MCQ battles over software engineering questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888953');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888954', '11111111-1111-1111-1111-111111111107', 'memory_match', 'Matching UML and process terms with definitions strengthens modelling vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888954');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888955', '11111111-1111-1111-1111-111111111107', 'speed_run', 'Timed recall drills reinforce fluent software engineering knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888955');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888956', '11111111-1111-1111-1111-111111111107', 'boss_battle', 'Mastery challenges over mixed software engineering questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888956');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888957', '11111111-1111-1111-1111-111111111107', 'snake_and_ladder', 'Board progression driven by software engineering questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888957');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888958', '11111111-1111-1111-1111-111111111107', 'target_challenge', 'Targeted drills focus practice on software engineering topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888958');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888959', '11111111-1111-1111-1111-111111111107', 'concept_builder', 'Assembling UML diagrams from elements practices applied software modelling.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888959');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888960', '11111111-1111-1111-1111-111111111107', 'drag_drop', 'Sorting elements into UML diagrams practices modelling classification.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888960');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888961', '11111111-1111-1111-1111-111111111107', 'mystery_case', 'Investigating design failure cases practices software diagnosis with case study thinking.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888961');

-- Web Technologies (111...108): 9 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888962', '11111111-1111-1111-1111-111111111108', 'quiz_battle', 'MCQ battles over web technology questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888962');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888963', '11111111-1111-1111-1111-111111111108', 'memory_match', 'Matching web terms with definitions strengthens HTML CSS and JS vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888963');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888964', '11111111-1111-1111-1111-111111111108', 'speed_run', 'Timed recall drills reinforce fluent web technology knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888964');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888965', '11111111-1111-1111-1111-111111111108', 'boss_battle', 'Mastery challenges over mixed web questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888965');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888966', '11111111-1111-1111-1111-111111111108', 'snake_and_ladder', 'Board progression driven by web questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888966');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888967', '11111111-1111-1111-1111-111111111108', 'target_challenge', 'Targeted drills focus practice on web technology topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888967');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888968', '11111111-1111-1111-1111-111111111108', 'debug_arena', 'Finding and fixing defects practices real web debugging skill.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888968');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888969', '11111111-1111-1111-1111-111111111108', 'unlock_code', 'Deriving codes from web answers practices applied client server problem solving.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888969');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888970', '11111111-1111-1111-1111-111111111108', 'drag_drop', 'Sorting tags and styles into documents practices web classification.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888970');

-- Artificial Intelligence and Machine Learning (111...109): 7 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888971', '11111111-1111-1111-1111-111111111109', 'quiz_battle', 'MCQ battles over AI and ML questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888971');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888972', '11111111-1111-1111-1111-111111111109', 'memory_match', 'Matching AI and ML terms with definitions strengthens modelling vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888972');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888973', '11111111-1111-1111-1111-111111111109', 'speed_run', 'Timed recall drills reinforce fluent AI and ML knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888973');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888974', '11111111-1111-1111-1111-111111111109', 'boss_battle', 'Mastery challenges over mixed AI and ML questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888974');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888975', '11111111-1111-1111-1111-111111111109', 'snake_and_ladder', 'Board progression driven by AI and ML questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888975');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888976', '11111111-1111-1111-1111-111111111109', 'target_challenge', 'Targeted drills focus practice on AI and ML topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888976');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888977', '11111111-1111-1111-1111-111111111109', 'concept_builder', 'Assembling models from algorithms and layers practices applied ML design.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888977');

-- Foundations of Data Science (111...110): 7 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888978', '11111111-1111-1111-1111-111111111110', 'quiz_battle', 'MCQ battles over data science questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888978');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888979', '11111111-1111-1111-1111-111111111110', 'memory_match', 'Matching data science terms with definitions strengthens analysis vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888979');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888980', '11111111-1111-1111-1111-111111111110', 'speed_run', 'Timed recall drills reinforce fluent data science knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888980');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888981', '11111111-1111-1111-1111-111111111110', 'boss_battle', 'Mastery challenges over mixed data science questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888981');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888982', '11111111-1111-1111-1111-111111111110', 'snake_and_ladder', 'Board progression driven by data science questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888982');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888983', '11111111-1111-1111-1111-111111111110', 'target_challenge', 'Targeted drills focus practice on data science topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888983');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888984', '11111111-1111-1111-1111-111111111110', 'sequence_master', 'Ordering preparation and analysis steps practices the data science pipeline.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888984');

-- Design and Analysis of Algorithms (111...111): 11 games
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888985', '11111111-1111-1111-1111-111111111111', 'quiz_battle', 'MCQ battles over algorithm questions build recall under pressure.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888985');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888986', '11111111-1111-1111-1111-111111111111', 'memory_match', 'Matching algorithm terms with definitions strengthens analysis vocabulary.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888986');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888987', '11111111-1111-1111-1111-111111111111', 'speed_run', 'Timed recall drills reinforce fluent algorithm knowledge.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888987');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888988', '11111111-1111-1111-1111-111111111111', 'boss_battle', 'Mastery challenges over mixed algorithm questions test readiness.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888988');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888989', '11111111-1111-1111-1111-111111111111', 'snake_and_ladder', 'Board progression driven by algorithm questions rewards persistence.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888989');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888990', '11111111-1111-1111-1111-111111111111', 'target_challenge', 'Targeted drills focus practice on algorithm topics.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888990');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888991', '11111111-1111-1111-1111-111111111111', 'debug_arena', 'Tracing and fixing algorithm defects practices real algorithm debugging skill.', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888991');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888992', '11111111-1111-1111-1111-111111111111', 'unlock_code', 'Deriving codes from algorithm answers practices applied complexity problem solving.', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888992');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888993', '11111111-1111-1111-1111-111111111111', 'concept_builder', 'Assembling algorithms from strategies practices applied algorithm design.', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888993');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888994', '11111111-1111-1111-1111-111111111111', 'sequence_master', 'Ordering divide, combine and recurrence steps practices algorithm procedures.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888994');
INSERT INTO subject_game_compat (id, subject_id, game_type, rationale, display_order, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888995', '11111111-1111-1111-1111-111111111111', 'puzzle_arena', 'Solving puzzles practices algorithm problem solving.', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subject_game_compat WHERE id = '88888888-8888-8888-8888-888888888995');
