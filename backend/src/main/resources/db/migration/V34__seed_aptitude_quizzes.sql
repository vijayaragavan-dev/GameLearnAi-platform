-- REALM-001 (quiz engine): assemble the existing 18 Aptitude questions
-- into one Quiz per Aptitude topic. DATA-ONLY migration: no question,
-- topic, subject, realm or compat row is created or modified here.
-- Follows the established one-quiz-per-topic convention
-- ("<Topic> Challenge", topic difficulty, CURATED, no time limit).

-- Percentages quiz (EASY)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01', '77777777-7777-7777-7777-777777777701', 'Percentages Challenge', 'Prove percent calculation skills.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01');

-- Profit and Loss quiz (EASY)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02', '77777777-7777-7777-7777-777777777702', 'Profit and Loss Challenge', 'Apply cost, price and margin reasoning.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02');

-- Ratio and Proportion quiz (MEDIUM)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03', '77777777-7777-7777-7777-777777777703', 'Ratio and Proportion Challenge', 'Split shares and scale ratios correctly.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03');

-- Number Series quiz (EASY)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa04', '77777777-7777-7777-7777-777777777704', 'Number Series Challenge', 'Spot arithmetic, geometric and mixed patterns.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa04');

-- Time and Work quiz (MEDIUM)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa05', '77777777-7777-7777-7777-777777777705', 'Time and Work Challenge', 'Combine work rates and convert time and distance.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa05');

-- Logical Reasoning quiz (MEDIUM)
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa06', '77777777-7777-7777-7777-777777777706', 'Logical Reasoning Challenge', 'Decode patterns, relations and directions.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa06');

-- Associations in deterministic question order (1, 2, 3 per quiz).
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc01', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01', '88888888-8888-8888-8888-888888888801', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc01');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc02', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01', '88888888-8888-8888-8888-888888888802', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc02');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc03', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa01', '88888888-8888-8888-8888-888888888803', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc03');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc04', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02', '88888888-8888-8888-8888-888888888804', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc04');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc05', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02', '88888888-8888-8888-8888-888888888805', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc05');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc06', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa02', '88888888-8888-8888-8888-888888888806', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc06');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc07', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03', '88888888-8888-8888-8888-888888888807', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc07');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc08', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03', '88888888-8888-8888-8888-888888888808', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc08');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc09', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa03', '88888888-8888-8888-8888-888888888809', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc09');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc10', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa04', '88888888-8888-8888-8888-888888888810', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc10');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc11', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa04', '88888888-8888-8888-8888-888888888811', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc11');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc12', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa04', '88888888-8888-8888-8888-888888888812', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc12');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc13', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa05', '88888888-8888-8888-8888-888888888813', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc13');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc14', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa05', '88888888-8888-8888-8888-888888888814', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc14');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc15', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa05', '88888888-8888-8888-8888-888888888815', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc15');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc16', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa06', '88888888-8888-8888-8888-888888888816', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc16');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc17', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa06', '88888888-8888-8888-8888-888888888817', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc17');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'cccccccc-cccc-cccc-cccc-cccccccccc18', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaa06', '88888888-8888-8888-8888-888888888818', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'cccccccc-cccc-cccc-cccc-cccccccccc18');
