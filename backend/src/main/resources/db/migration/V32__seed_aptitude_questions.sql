-- REALM-001: genuine Aptitude MVP question set (18 curated MCQs).
-- Every answer was verified by hand; options_json follows the exact
-- {"options": [...]} shape and correct_answer matches one option verbatim.
-- Topics: Percentages (..701), Profit and Loss (..702), Ratio (..703),
-- Number Series (..704), Time and Work (..705), Logical Reasoning (..706).

-- Percentages (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888801', '77777777-7777-7777-7777-777777777701', 'What is 25% of 200?', 'MCQ', 'EASY', '{"options": ["25", "50", "75", "100"]}', '50', '25% is one quarter; 200 divided by 4 is 50.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888801');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888802', '77777777-7777-7777-7777-777777777701', 'A price rises from 80 to 100. What is the percent increase?', 'MCQ', 'EASY', '{"options": ["20%", "25%", "30%", "125%"]}', '25%', 'Increase is 20 on a base of 80; 20 divided by 80 is 25%.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888802');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888803', '77777777-7777-7777-7777-777777777701', '40% of a number is 120. What is the number?', 'MCQ', 'EASY', '{"options": ["200", "280", "300", "480"]}', '300', 'Divide 120 by 0.40 to recover the whole: 300.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888803');

-- Profit and Loss (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888804', '77777777-7777-7777-7777-777777777702', 'An item bought for 500 is sold for 600. What is the profit percent?', 'MCQ', 'EASY', '{"options": ["15%", "20%", "25%", "120%"]}', '20%', 'Profit is 100 on cost 500; 100 divided by 500 is 20%.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888804');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888805', '77777777-7777-7777-7777-777777777702', 'An item bought for 800 is sold for 720. What is the loss percent?', 'MCQ', 'EASY', '{"options": ["8%", "10%", "11%", "80%"]}', '10%', 'Loss is 80 on cost 800; 80 divided by 800 is 10%.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888805');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888806', '77777777-7777-7777-7777-777777777702', 'A shopkeeper wants 25% profit on cost price 1200. What should the selling price be?', 'MCQ', 'EASY', '{"options": ["1350", "1450", "1500", "1600"]}', '1500', 'Selling price is 125% of 1200, which is 1500.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888806');

-- Ratio and Proportion (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888807', '77777777-7777-7777-7777-777777777703', 'Divide 600 in the ratio 2:3. What is the smaller share?', 'MCQ', 'MEDIUM', '{"options": ["200", "240", "300", "360"]}', '240', 'Two parts out of five total: 600 times 2 divided by 5 is 240.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888807');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888808', '77777777-7777-7777-7777-777777777703', 'If a:b is 3:4 and b:c is 2:5, what is a:c?', 'MCQ', 'MEDIUM', '{"options": ["3:10", "3:5", "6:5", "3:4"]}', '3:10', 'Scale b to 4 in both ratios: a:b is 3:4 and b:c is 4:10, so a:c is 3:10.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888808');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888809', '77777777-7777-7777-7777-777777777703', 'A 40 litre mixture has milk and water in the ratio 3:1. How many litres are water?', 'MCQ', 'MEDIUM', '{"options": ["8 litres", "10 litres", "12 litres", "30 litres"]}', '10 litres', 'One part out of four total: 40 divided by 4 is 10 litres of water.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888809');

-- Number Series (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888810', '77777777-7777-7777-7777-777777777704', 'Find the next number: 2, 5, 8, 11, ?', 'MCQ', 'EASY', '{"options": ["12", "13", "14", "15"]}', '14', 'Each term adds 3; 11 plus 3 is 14.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888810');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888811', '77777777-7777-7777-7777-777777777704', 'Find the next number: 3, 6, 12, 24, ?', 'MCQ', 'EASY', '{"options": ["36", "42", "48", "30"]}', '48', 'Each term doubles; 24 times 2 is 48.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888811');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888812', '77777777-7777-7777-7777-777777777704', 'Find the next number: 100, 90, 81, 73, ?', 'MCQ', 'EASY', '{"options": ["64", "65", "66", "72"]}', '66', 'Differences shrink by one each step (10, 9, 8); 73 minus 7 is 66.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888812');

-- Time and Work (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888813', '77777777-7777-7777-7777-777777777705', 'A finishes a job in 6 days and B in 12 days. Working together, how many days do they need?', 'MCQ', 'MEDIUM', '{"options": ["3 days", "4 days", "6 days", "9 days"]}', '4 days', 'Combined rate is one sixth plus one twelfth, or one quarter of the job per day: 4 days.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888813');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888814', '77777777-7777-7777-7777-777777777705', '5 workers finish a task in 8 days. How many days do 10 workers need at the same pace?', 'MCQ', 'MEDIUM', '{"options": ["2 days", "4 days", "6 days", "16 days"]}', '4 days', 'Total work is 40 worker-days; 10 workers finish it in 4 days.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888814');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888815', '77777777-7777-7777-7777-777777777705', 'A train travels at 60 km/h for 3 hours. How far does it go?', 'MCQ', 'MEDIUM', '{"options": ["120 km", "150 km", "180 km", "200 km"]}', '180 km', 'Distance is speed times time: 60 times 3 is 180 km.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888815');

-- Logical Reasoning (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888816', '77777777-7777-7777-7777-777777777706', 'If CAT is coded as 3120 (A=1, B=2, ...), how is DOG coded?', 'MCQ', 'MEDIUM', '{"options": ["4157", "4156", "5147", "4715"]}', '4157', 'Replace each letter by its position: D is 4, O is 15, G is 7.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888816');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888817', '77777777-7777-7777-7777-777777777706', 'A man points at a photo and says: she is the daughter of the only son of my grandmother. Who is she?', 'MCQ', 'MEDIUM', '{"options": ["Mother", "Sister", "Aunt", "Cousin"]}', 'Sister', 'The only son of the grandmother is the father, and his daughter is the sister.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888817');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '88888888-8888-8888-8888-888888888818', '77777777-7777-7777-7777-777777777706', 'You face north, turn right, then turn right again. Which direction do you face now?', 'MCQ', 'MEDIUM', '{"options": ["North", "South", "East", "West"]}', 'South', 'North to east on the first right, east to south on the second.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '88888888-8888-8888-8888-888888888818');
