-- REALM-001 Phase 2: Logical Reasoning import (330 playable practice
-- questions across 22 new Aptitude topics). Generated deterministically
-- from LR/data/questions.json; verified preconditions:
-- 352 records / 22 concepts / 15 practice each / 330 answers valid /
-- 0 duplicates / 0 overlap with existing 18 Aptitude MCQs /
-- LR-11-1-01 (unverified) + 22 info items EXCLUDED by construction.
-- Idempotent INSERT...SELECT...WHERE NOT EXISTS pattern.
-- Quiz difficulty MEDIUM: every section is exactly 5 Easy + 5 Medium
-- + 5 Hard, so the middle value is the only deterministic choice.

-- Alphanumeric Series -> topic Alphanumeric Series
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000001', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Alphanumeric Series', 'Involves sequences containing both letters and numbers where a pattern must be identified or completed', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000001');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000001', 'dddddddd-dddd-dddd-dddd-000000000001', 'Alphanumeric Series Challenge', 'Apply alphanumeric series skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000001');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000000', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next term in the alternating letter-number pattern: A2, D4, G6, J8, M10, ?', 'MCQ', 'HARD', '{"options": ["P12", "Q14", "N12", "R14", "O12"]}', 'P12', 'Letters increase by +3; numbers +2 each time. After M(13): +3→P(16); number: 10+2=12. Correct answer: P12.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000000');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000000', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000000', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000000');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000001', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next letter in the given sequence based on the alphabetical pattern: B, E, H, K, ?', 'MCQ', 'MEDIUM', '{"options": ["N", "P", "M", "O", "Q"]}', 'N', 'Positions increase by +3: B(2), E(5), H(8), K(11) → next = N(14). Correct answer: N.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000001');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000001', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000001', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000001');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000002', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next number in the following numerical progression: 5, 10, 20, 40, ?', 'MCQ', 'MEDIUM', '{"options": ["60", "80", "90", "100", "70"]}', '80', 'Each term doubles the previous one (×2). 40×2=80. Correct answer: 80.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000002');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000002', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000002', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000002');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000003', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next pair of letters in the following reversal pattern: AZ, BY, CX, DW, ?', 'MCQ', 'HARD', '{"options": ["FU", "EV", "FV", "FW", "EU"]}', 'EV', 'First letter increases by +1; second letter decreases by –1. After D(4)→E(5), W(23)→V(22). Correct answer: EV.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000003');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000003', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000003', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000003');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000004', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next letter in the given sequence based on the alphabetical pattern: A, C, E, G, ?', 'MCQ', 'EASY', '{"options": ["K", "L", "H", "I", "J"]}', 'I', 'Letters increase by +2 each time: A(1), C(3), E(5), G(7), so next is I(9). Correct answer: I.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000004');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000004', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000004', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000004');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000005', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next term following both letter and number double-increment pattern: A1, C3, F6, J10, ?', 'MCQ', 'HARD', '{"options": ["O15", "L12", "N14", "P16", "M13"]}', 'O15', 'Pattern: letters and numbers both follow increasing increments of +2, +3, +4, ... Letter positions: A(1), C(3), F(6), J(10) → increments +2, +3, +4 → next increment +5 → 10 + 5 = 15 → letter at position 15 = O. Numbers: 1, 3, 6, 10 are triangular numbers (add 2, 3, 4...) → next = 10 + 5 = 15. Next term = O15.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000005');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000005', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000005', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000005');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000006', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next alphanumeric term following the given pattern of letters and numbers: A1, B2, C3, D4, ?', 'MCQ', 'EASY', '{"options": ["F6", "F5", "E5", "E6", "E4"]}', 'E5', 'Letter and number both increase by +1 each step. So after D4 comes E5. Correct answer: E5.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000006');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000006', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000006', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000006');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000007', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next term in the interlaced letter-number sequence: A1, A3, B5, B7, C9, ?', 'MCQ', 'HARD', '{"options": ["E15", "D11", "C11", "C12", "D13"]}', 'C11', 'Odd positions repeat letters twice; numbers increase by +2. Next = C11. Correct answer: C11.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000007');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000007', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000007', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000007');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000008', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next term in the series: A1\$, C2#, F4$, J7#, ?', 'MCQ', 'EASY', '{"options": ["O11#", "O11$", "N11#", "P11#", "M11#"]}', 'O11$', 'Pattern: letters and numbers both follow increasing increments (+2, +3, +4, ...). Letters: A(1), C(3), F(6), J(10) → next position = 10 + 5 = 15 → letter = O. Numbers: 1, 2, 4, 7 → differences +1, +2, +3 → next = 7 + 4 = 11.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000008');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000008', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000008', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000008');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000009', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next coded term in the series: 1C, 4F, 9I, 16L, ?', 'MCQ', 'HARD', '{"options": ["20P", "25O", "30Q", "25P", "20O"]}', '25O', 'Numbers: squares (1,4,9,16,25); letters +3 each time (C,F,I,L,O). Correct answer: 25O.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000009');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000009', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000009', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000009');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000a', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the missing term in the following series: 3A, 6C, 9E, 12G, ?', 'MCQ', 'EASY', '{"options": ["15I", "15H", "18I", "15J", "18H"]}', '15I', 'Numbers increase by +3; letters by +2. So next term: 15I. Correct answer: 15I.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000a', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000a', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000b', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next number in the following numerical pattern: 2, 4, 8, 16, ?', 'MCQ', 'EASY', '{"options": ["24", "36", "18", "30", "32"]}', '32', 'Pattern: Each term doubles the previous one (×2). Hence next = 16×2 = 32. Correct answer: 32.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000b', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000b', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000c', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the next alphanumeric term in the series combining letters and numbers: A2B, C4D, E6F, G8H, ?', 'MCQ', 'MEDIUM', '{"options": ["J10K", "I12J", "I10J", "K12L", "J8K"]}', 'I10J', 'Letters increase by +2 each; numbers by +2. So next: I10J. Correct answer: I10J.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000c', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000c', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000d', 'dddddddd-dddd-dddd-dddd-000000000001', 'Find the next term in the given mixed letter-number pattern: Z5, Y10, X15, W20, ?', 'MCQ', 'MEDIUM', '{"options": ["V30", "T25", "U30", "V25", "U25"]}', 'V25', 'Letters move backward (–1); numbers +5 each time. Next: V25. Correct answer: V25.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000d', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000d', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000e', 'dddddddd-dddd-dddd-dddd-000000000001', 'Identify the wrong term in the following series: 2A, 4C, 6E, 8G, 10I', 'MCQ', 'MEDIUM', '{"options": ["8G", "10I", "All Correct", "4C", "6E"]}', 'All Correct', 'Numbers increase by +2; letters by +2 each time. All follow rule, so no wrong term. Correct answer: All Correct.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000e', 'eeeeeeee-eeee-eeee-eeee-000000000001', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000e', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000e');

-- Number Series -> topic Number Series (LR)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000002', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Number Series (LR)', 'Deals with numerical sequences requiring identification of logical or arithmetic patterns', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000002');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000002', 'dddddddd-dddd-dddd-dddd-000000000002', 'Number Series (LR) Challenge', 'Apply number series (lr) skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000002');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000f', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term in the geometric sequence: 5, 10, 20, 40, 80, ?', 'MCQ', 'EASY', '{"options": ["120", "200", "240", "320", "160"]}', '160', 'Explanation: This is a geometric series with common ratio ×2. Step 1: 5×2=10 Step 2: 10×2=20 Step 3: 20×2=40 Step 4: 40×2=80 Next = 80×2 = 160. Correct answer: 160.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000f', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000000f', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000000f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000010', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term where differences double each time: 2, 5, 11, 23, 47, ?', 'MCQ', 'HARD', '{"options": ["99", "95", "103", "101", "97"]}', '95', 'Differences: 5−2=3, 11−5=6, 23−11=12, 47−23=24. The differences are doubling each time: 3, 6, 12, 24 → next difference = 48. Add to the last term: 47 + 48 = 95. Next term = 95', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000010');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000010', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000010', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000010');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000011', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term in the series with increasing differences: 2, 6, 12, 20, 30, ?', 'MCQ', 'MEDIUM', '{"options": ["48", "46", "40", "44", "42"]}', '42', 'Explanation: Differences increase by +2 each time. Step 1: 6−2=4 Step 2: 12−6=6 Step 3: 20−12=8 Step 4: 30−20=10 Next difference = 10+2=12 Next = 30+12=42. Correct answer: 42.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000011');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000011', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000011', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000011');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000012', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term in the geometric pattern: 7, 14, 28, 56, 112, ?', 'MCQ', 'HARD', '{"options": ["256", "224", "384", "168", "196"]}', '224', 'Explanation: This is a geometric progression with ratio ×2. Step 1: 7×2=14 Step 2: 14×2=28 Step 3: 28×2=56 Step 4: 56×2=112 Next = 112×2=224. Correct answer: 224.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000012');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000012', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000012', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000012');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000013', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the recursive pattern (×2 − 1): 4, 7, 13, 25, 49, ?', 'MCQ', 'MEDIUM', '{"options": ["99", "98", "101", "100", "97"]}', '97', 'Explanation: Each term is obtained by multiplying the previous term by 2 and subtracting 1. Step 1: 4×2−1=7 Step 2: 7×2−1=13 Step 3: 13×2−1=25 Step 4: 25×2−1=49 Next = 49×2−1 = 97. Correct answer: 97.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000013');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000013', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000013', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000013');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000014', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the following sequence: 0, 1, 2, 9, 44, ?', 'MCQ', 'HARD', '{"options": ["132", "220", "270", "265", "320"]}', '265', 'Observe that the sequence matches the subfactorial (derangement) numbers {aₙ} = {1, 0, 1, 2, 9, 44, 265, …}. For n = 0 → a₀ = 1, a₁ = 0, a₂ = 1, a₃ = 2, a₄ = 9, a₅ = 44, a₆ = 265. The given sequence 0, 1, 2, 9, 44 corresponds to a₁, a₃, a₄, a₅ (pattern-shifted positions). Hence, the next term follows as a₆ = 265. Next term = 265.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000014');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000014', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000014', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000014');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000015', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the factorial sequence: 1, 2, 6, 24, 120, ?', 'MCQ', 'MEDIUM', '{"options": ["600", "240", "360", "840", "720"]}', '720', 'Explanation: Each term represents n! (n factorial). Step 1: 1!=1 Step 2: 2!=2 Step 3: 3!=6 Step 4: 4!=24 Step 5: 5!=120 Next = 6! = 720. Correct answer: 720.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000015');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000015', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000015', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000015');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000016', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term in the prime-based arithmetic pattern: 11, 13, 17, 23, 31, ?', 'MCQ', 'MEDIUM', '{"options": ["41", "47", "53", "37", "43"]}', '41', 'Explanation: Differences follow +2, +4, +6, +8 — increasing by +2 each step. Step 1: 13−11=2 Step 2: 17−13=4 Step 3: 23−17=6 Step 4: 31−23=8 Next difference = 8+2=10 Next = 31+10=41. Correct answer: 41.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000016');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000016', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000016', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000016');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000017', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the arithmetic sequence: 2, 4, 6, 8, ?', 'MCQ', 'EASY', '{"options": ["11", "10", "12", "9", "14"]}', '10', 'Explanation: This is an arithmetic series with common difference +2. Step 1: 2→4 (+2) Step 2: 4→6 (+2) Step 3: 6→8 (+2) Next = 8+2 = 10. Correct answer: 10.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000017');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000017', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000017', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000017');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000018', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the sequence of perfect squares: 1, 4, 9, 16, ?', 'MCQ', 'EASY', '{"options": ["24", "20", "23", "25", "21"]}', '25', 'Explanation: This is a sequence of perfect squares n². Step 1: 1²=1 Step 2: 2²=4 Step 3: 3²=9 Step 4: 4²=16 Next = 5² = 25. Correct answer: 25.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000018');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000018', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000018', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000018');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000019', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the series with doubling differences: 3, 5, 9, 17, 33, ?', 'MCQ', 'HARD', '{"options": ["66", "97", "81", "49", "65"]}', '65', 'Explanation: Differences double each step. Step 1: 5−3=2 Step 2: 9−5=4 Step 3: 17−9=8 Step 4: 33−17=16 Next difference = 16×2=32 Next = 33+32=65. Correct answer: 65.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000019');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000019', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000019', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000019');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001a', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the geometric progression: 3, 9, 27, 81, ?', 'MCQ', 'EASY', '{"options": ["405", "162", "243", "486", "324"]}', '243', 'Explanation: This is a geometric series with common ratio ×3. Step 1: 3×3=9 Step 2: 9×3=27 Step 3: 27×3=81 Next = 81×3 = 243. Correct answer: 243.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001a', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001a', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001b', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term in the series with decreasing differences: 10, 9, 7, 4, 0, ?', 'MCQ', 'MEDIUM', '{"options": ["-4", "-3", "-1", "-2", "-5"]}', '-5', 'Explanation: Successive differences are −1, −2, −3, −4 — each decreasing by 1 more. Step 1: 9−10=−1 Step 2: 7−9=−2 Step 3: 4−7=−3 Step 4: 0−4=−4 Next difference = −5 Next = 0 + (−5) = −5. Correct answer: −5.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001b', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001b', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001c', 'dddddddd-dddd-dddd-dddd-000000000002', 'Identify the next term in the Fibonacci sequence: 0, 1, 1, 2, 3, 5, ?', 'MCQ', 'EASY', '{"options": ["10", "9", "7", "6", "8"]}', '8', 'Explanation: This is a Fibonacci sequence where each term is the sum of the previous two. Step 1: 2+3=5 (given) Step 2: 3+5 = 8 Correct answer: 8.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001c', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001c', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001d', 'dddddddd-dddd-dddd-dddd-000000000002', 'Find the next term where differences increase linearly: 2, 12, 30, 56, 90, ?', 'MCQ', 'HARD', '{"options": ["140", "182", "210", "132", "156"]}', '132', 'Explanation: Differences increase by +8 each time. Step 1: 12−2=10 Step 2: 30−12=18 Step 3: 56−30=26 Step 4: 90−56=34 Next difference = 34+8=42 Next = 90+42=132. Correct answer: 132.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001d', 'eeeeeeee-eeee-eeee-eeee-000000000002', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001d', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001d');

-- Classification -> topic Classification
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000003', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Classification', 'Involves identifying the odd one out among given items based on common properties', 'MEDIUM', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000003');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000003', 'dddddddd-dddd-dddd-dddd-000000000003', 'Classification Challenge', 'Apply classification skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000003');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001e', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one: Honesty, Bravery, Wisdom, Tiger', 'MCQ', 'HARD', '{"options": ["Bravery", "Tiger", "Kindness", "Honesty", "Wisdom"]}', 'Tiger', 'Explanation: Honesty, Bravery, and Wisdom are qualities; Tiger is an animal. Step 1: Identify abstract vs. concrete nouns. Step 2: Tiger differs. Final: Tiger is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001e', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001e', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001f', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one: FH, IK, NP, QS, VX', 'MCQ', 'HARD', '{"options": ["NP", "FH", "IK", "QS", "VX"]}', 'IK', 'Explanation: Each pair has a +2 letter difference, but only “IK” includes a vowel while others are consonant pairs. Step 1: Compare vowel/consonant composition. Step 2: IK has vowel K pattern. Final: IK is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001f', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000001f', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000001f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000020', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd word: Rose, Lily, Lotus, Mango', 'MCQ', 'EASY', '{"options": ["Rose", "Lily", "Lotus", "Mango", "None"]}', 'Mango', 'Explanation: Rose, Lily, and Lotus are flowers; Mango is a fruit. Step 1: Group by category. Step 2: Flowers vs. fruit. Step 3: Mango is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000020');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000020', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000020', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000020');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000021', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd number: 2, 4, 6, 9', 'MCQ', 'EASY', '{"options": ["9", "2", "6", "8", "4"]}', '9', 'Explanation: 2, 4, and 6 are even; 9 is odd. Step 1: Check even/odd. Step 2: 9 is odd. Step 3: Hence, 9 is the odd number.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000021');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000021', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000021', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000021');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000022', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one: 4, 9, 16, 25, 27', 'MCQ', 'HARD', '{"options": ["4", "16", "25", "9", "27"]}', '27', 'Explanation: 4, 9, 16, and 25 are perfect squares; 27 is a cube. Step 1: Identify number type. Step 2: 27 is cube. Final: 27 is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000022');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000022', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000022', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000022');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000023', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd word: Iron, Copper, Silver, Wood', 'MCQ', 'MEDIUM', '{"options": ["Iron", "Copper", "Gold", "Silver", "Wood"]}', 'Wood', 'Explanation: Iron, Copper, and Silver are metals; Wood is non-metal. Step 1: Identify material type. Step 2: Metals vs. non-metal. Step 3: Wood differs.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000023');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000023', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000023', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000023');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000024', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd pair: AZ, BY, CX, DW', 'MCQ', 'MEDIUM', '{"options": ["AZ", "BY", "CX", "DW", "No odd pair"]}', 'No odd pair', 'Explanation: Each pair has letters whose positions add up to 27 (A+Z=27, B+Y=27, C+X=27, D+W=27). Step 1: All follow the same mirror pattern. Step 2: None is odd. Final: No odd pair.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000024');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000024', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000024', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000024');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000025', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd number: 16, 25, 36, 49, 50', 'MCQ', 'MEDIUM', '{"options": ["16", "25", "36", "50", "49"]}', '50', 'Explanation: 16, 25, 36, and 49 are perfect squares; 50 is not. Step 1: Check for perfect squares. Step 2: 50 not square. Final: 50 is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000025');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000025', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000025', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000025');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000026', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd word: Table, Chair, Bed, Spoon', 'MCQ', 'MEDIUM', '{"options": ["Chair", "None", "Bed", "Spoon", "Table"]}', 'Spoon', 'Explanation: Table, Chair, and Bed are furniture; Spoon is a utensil. Step 1: Group by category. Step 2: Identify differing item. Final: Spoon differs.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000026');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000026', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000026', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000026');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000027', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd number: 121, 144, 169, 196, 200', 'MCQ', 'HARD', '{"options": ["121", "144", "200", "196", "169"]}', '200', 'Explanation: 121, 144, 169, and 196 are perfect squares; 200 is not. Step 1: Check each number. Step 2: Only 200 breaks the square pattern. Final: 200 is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000027');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000027', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000027', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000027');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000028', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one out: 3, 5, 7, 9, 11', 'MCQ', 'MEDIUM', '{"options": ["3", "5", "9", "7", "11"]}', '9', 'Explanation: 3, 5, 7, and 11 are prime; 9 is not. Step 1: Check for prime numbers. Step 2: 9 is composite. Final: 9 is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000028');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000028', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000028', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000028');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000029', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd pair: $AB$, $CD$, $EF$, $GH$, $IK$', 'MCQ', 'EASY', '{"options": ["$GH$", "$AB$", "$IK$", "$CD$", "$EF$"]}', '$IK$', 'Explanation: Step 1: Convert letters to positions — A=1, B=2 → AB gap = +1; C=3, D=4 → +1; E=5, F=6 → +1; G=7, H=8 → +1; I=9, K=11 → +2. Step 2: All pairs have +1 gap except IK which has +2. Final: IK is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000029');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000029', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000029', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000029');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002a', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one out: Apple, Banana, Mango, Carrot', 'MCQ', 'EASY', '{"options": ["Apple", "Banana", "Mango", "Carrot", "None of these"]}', 'Carrot', 'Explanation: Apple, Banana, and Mango are fruits; Carrot is a vegetable. Step 1: Identify category. Step 2: Compare fruits vs. vegetable. Step 3: Carrot differs.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002a', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002a', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002b', 'dddddddd-dddd-dddd-dddd-000000000003', 'Find the odd one: Dog, Cat, Cow, Chair', 'MCQ', 'EASY', '{"options": ["None", "Cow", "Dog", "Chair", "Cat"]}', 'Chair', 'Explanation: Dog, Cat, and Cow are animals; Chair is not. Step 1: Group by living vs. non-living. Step 2: Chair differs. Final: Chair is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002b', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002b', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002c', 'dddddddd-dddd-dddd-dddd-000000000003', 'Which is the odd one: Square, Triangle, Rectangle, Cube', 'MCQ', 'HARD', '{"options": ["None", "Cube", "Triangle", "Square", "Rectangle"]}', 'Cube', 'Explanation: Square, Triangle, and Rectangle are 2D shapes; Cube is 3D. Step 1: Check dimensionality. Step 2: Cube differs. Final: Cube is the odd one out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002c', 'eeeeeeee-eeee-eeee-eeee-000000000003', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002c', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002c');

-- Blood Relations -> topic Blood Relations
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000004', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Blood Relations', 'Analyzes family relationships based on given descriptions to identify connections', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000004');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000004', 'dddddddd-dddd-dddd-dddd-000000000004', 'Blood Relations Challenge', 'Apply blood relations skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000004');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002d', 'dddddddd-dddd-dddd-dddd-000000000004', 'Pointing to a woman, Sohan says, "Her father is the only son of my grandfather." How is the woman related to Sohan?', 'MCQ', 'EASY', '{"options": ["Cousin", "Sister", "Mother", "Daughter", "Aunt"]}', 'Sister', 'Explanation: "My grandfather''s only son" = Sohan''s father. Her father = Sohan''s father → She is Sohan''s sister. Final Answer: Sister.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002d', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002d', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002e', 'dddddddd-dddd-dddd-dddd-000000000004', 'X is the son of Y. Y is the daughter of Z. Z is the brother of W. How is W related to X?', 'MCQ', 'MEDIUM', '{"options": ["Uncle", "Grandfather", "Great-aunt or Great-uncle", "Cousin", "Cannot be determined"]}', 'Great-aunt or Great-uncle', 'Explanation: Y is Z''s daughter → Z is Y''s father. Z is brother of W → W is sibling of Z. X is child of Y → W is sibling of X’s grandparent → Great-aunt or Great-uncle. Final Answer: Great-aunt or Great-uncle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002e', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002e', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002f', 'dddddddd-dddd-dddd-dddd-000000000004', 'P said, "Q is the only son of the only sister of my mother." How is Q related to P?', 'MCQ', 'HARD', '{"options": ["Cousin", "Brother", "Nephew", "Uncle", "Cannot be determined"]}', 'Cousin', 'Explanation: Only sister of my mother = my maternal aunt. Her only son Q = my cousin. Final Answer: Cousin.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002f', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000002f', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000002f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000030', 'dddddddd-dddd-dddd-dddd-000000000004', 'A is the father of B. B is the mother of C. How is A related to C?', 'MCQ', 'EASY', '{"options": ["Father", "Great-grandfather", "Uncle", "Brother", "Grandfather"]}', 'Grandfather', 'Explanation: B is C''s mother; A is B''s father. So A is the father of C''s mother → grandfather of C. Final Answer: Grandfather.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000030');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000030', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000030', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000030');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000031', 'dddddddd-dddd-dddd-dddd-000000000004', 'A is the son of B. C is the daughter of D. B is the brother of D. How is A related to C?', 'MCQ', 'HARD', '{"options": ["Brother", "Uncle", "Cousin", "Grandson", "Nephew"]}', 'Cousin', 'Explanation: B and D are siblings. A is son of B; C is daughter of D. Children of siblings are cousins. Final Answer: Cousins.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000031');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000031', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000031', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000031');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000032', 'dddddddd-dddd-dddd-dddd-000000000004', 'P and Q are siblings. P is the mother of R. How is Q related to R?', 'MCQ', 'EASY', '{"options": ["Aunt/Uncle", "Cousin", "Grandparent", "Father", "Mother"]}', 'Aunt/Uncle', 'Explanation: P is R''s mother; Q is P''s sibling. So Q is the sibling of R''s mother → R''s aunt or uncle. Final Answer: Aunt/Uncle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000032');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000032', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000032', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000032');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000033', 'dddddddd-dddd-dddd-dddd-000000000004', 'If ''A % B'' means ''A is the daughter of B'' and ''A & B'' means ''A is the sister of B'', what does ''P & Q % R'' mean?', 'MCQ', 'HARD', '{"options": ["P is aunt of R", "P is niece of R", "P is daughter of R", "P is sister of R", "P is mother of R"]}', 'P is daughter of R', 'Explanation: P & Q → P is sister of Q. Q % R → Q is daughter of R. So both P and Q are daughters of R → P is daughter of R. Final Answer: Daughter.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000033');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000033', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000033', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000033');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000034', 'dddddddd-dddd-dddd-dddd-000000000004', 'If ''P # Q'' means ''P is the brother of Q'' and ''P \$ Q'' means ''P is the mother of Q'', what does ''A # B $ C'' mean?', 'MCQ', 'MEDIUM', '{"options": ["A is nephew of C", "A is uncle of C", "A is father of C", "A is brother of C", "A is grandfather of C"]}', 'A is uncle of C', 'Explanation: A # B → A is brother of B. B $ C → B is mother of C. So A is brother of C’s mother → maternal uncle of C. Final Answer: Maternal Uncle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000034');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000034', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000034', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000034');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000035', 'dddddddd-dddd-dddd-dddd-000000000004', 'Pointing to a man, Neha said, "He is the only son of my mother''s brother." How is the man related to Neha?', 'MCQ', 'MEDIUM', '{"options": ["Brother", "Father", "Uncle", "Cousin", "Nephew"]}', 'Brother', 'Explanation: Mother’s brother = Neha’s maternal uncle. His only son = Neha’s cousin (male). Final Answer: Cousin.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000035');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000035', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000035', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000035');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000036', 'dddddddd-dddd-dddd-dddd-000000000004', 'Pointing to a man, Ravi said, "He is the son of my mother''s only daughter." How is the man related to Ravi?', 'MCQ', 'EASY', '{"options": ["Brother", "Cousin", "Uncle", "Nephew", "Cannot be determined"]}', 'Nephew', 'Explanation: Ravi''s mother''s only daughter = Ravi''s sister (since Ravi is male). Son of Ravi''s sister = Ravi''s nephew. Final Answer: Nephew.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000036');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000036', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000036', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000036');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000037', 'dddddddd-dddd-dddd-dddd-000000000004', 'P is the brother of Q. Q is the mother of R. R is the sister of S. How is P related to S?', 'MCQ', 'MEDIUM', '{"options": ["Brother", "Father", "Uncle", "Cousin", "Grandfather"]}', 'Uncle', 'Explanation: Q is mother of R, and R is sister of S → Q is also mother of S. P is brother of Q → P is maternal uncle of S. Final Answer: Maternal Uncle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000037');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000037', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000037', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000037');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000038', 'dddddddd-dddd-dddd-dddd-000000000004', 'X''s father is Y. Y''s mother is Z. Z is the sister of W. How is W related to X?', 'MCQ', 'HARD', '{"options": ["Grandmother", "Great-aunt", "Great-grandmother", "Aunt", "Cannot be determined"]}', 'Great-aunt', 'Explanation: Y’s mother = Z (grandmother of X). Z is sister of W → W is sibling of X’s grandmother → great-aunt. Final Answer: Great-Aunt.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000038');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000038', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000038', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000038');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000039', 'dddddddd-dddd-dddd-dddd-000000000004', 'A is the mother of B. C is the brother of B. D is the daughter of C. How is D related to A?', 'MCQ', 'MEDIUM', '{"options": ["Daughter", "Sister", "Granddaughter", "Niece", "Cousin"]}', 'Granddaughter', 'Explanation: B and C are siblings → C''s daughter D is B''s niece. A is mother of B (and C) → D is A’s granddaughter. Final Answer: Granddaughter.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000039');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000039', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000039', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000039');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003a', 'dddddddd-dddd-dddd-dddd-000000000004', 'M has only one child N. N has two children P and Q. Q is the father of R. How is R related to M?', 'MCQ', 'HARD', '{"options": ["Grandchild", "Great-grandchild", "Great-great-grandchild", "Niece/Nephew", "Cannot be determined"]}', 'Great-grandchild', 'Explanation: M is parent of N → N’s children are P and Q (grandchildren of M). Q’s child is R → R is great-grandchild of M. Final Answer: Great-Grandchild.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003a', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003a', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003b', 'dddddddd-dddd-dddd-dddd-000000000004', 'If A + B means A is the father of B, and A − B means A is the sister of B, what does P − Q + R mean?', 'MCQ', 'EASY', '{"options": ["P is grandmother of R", "P is mother of R", "P is sister of R", "P is niece of R", "P is aunt of R"]}', 'P is aunt of R', 'Explanation: P − Q → P is sister of Q. Q + R → Q is father of R. So P is sister of R''s father → R''s aunt. Final Answer: Aunt.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003b', 'eeeeeeee-eeee-eeee-eeee-000000000004', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003b', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003b');

-- Order and Ranking -> topic Order and Ranking
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000005', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Order and Ranking', 'Determines position of individuals or objects based on rank, order, or quantitative conditions', 'MEDIUM', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000005');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000005', 'dddddddd-dddd-dddd-dddd-000000000005', 'Order and Ranking Challenge', 'Apply order and ranking skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000005');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003c', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row of 15 students, Priya is 6th from the left end. What is her position from the right end?', 'MCQ', 'EASY', '{"options": ["9th", "10th", "11th", "12th", "13th"]}', '10th', 'Using formula: Right Rank = Total - Left Rank + 1.
 Right Rank = 15 - 6 + 1 = 10th from the right end.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003c', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003c', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003d', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row, Person A is 12th from the left end. Person B is 20th from the right end. When A and B exchange their positions, A becomes 16th from the left end. Person C is standing exactly in the middle of A''s initial position and A''s final position.What is Person C''s position from the right end of the row?', 'MCQ', 'HARD', '{"options": ["18th", "19th", "21st", "22nd", "25th"]}', '22nd', 'A''s initial position from left = 12th
A''s final position from left = 16th (after swap with B)
B''s initial position from right = 20th
B''s position from left = 16th (A''s final position)
Total people = (16 + 20) - 1 = 35
A''s initial (12th) and final (16th) positions'' midpoint = C''s position
C''s position from left = (12 + 16)/2 = 14th
C''s position from right = 35 - 14 + 1 = 22nd.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003d', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003d', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003e', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row, Arun is 6th from the left and Bhavna is 7th from the right. If 3 people are standing between them, how many people are there in total?', 'MCQ', 'MEDIUM', '{"options": ["15", "16", "17", "18", "19"]}', '16', 'Arun is 6th from left means 5 people before him + Arun = 6 positions.
 Bhavna is 7th from right means 6 people after her.
 With 3 people between them: Total = 5 + 1 + 3 + 1 + 6 = 16 people.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003e', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003e', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003f', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a race result ranking, Arjun''s rank is 17th from the top. Bhavna''s rank is 24th from the bottom. When they exchange their positions, Arjun''s rank becomes 12th from the top. If the race initially had 50 runners, and then 3 new runners are added to the ranking before Arjun''s new position (with better ranks), what will be Bhavna''s rank from the top in the final updated ranking?', 'MCQ', 'HARD', '{"options": ["19th", "20th", "21st", "22nd", "23rd"]}', '20th', 'Total initial runners = 50.
Arjun''s initial rank from top = 17th
Bhavna''s rank from bottom = 24th → from top = 50 - 24 + 1 = 27th
Arjun''s rank after swap = 12th (at Bhavna''s initial position)
Arjun''s new position (12th) gets 3 new runners before → 12 + 3 = 15th (Arjun''s final position)
Bhavna''s position after swap = Arjun''s initial = 17th
Bhavna''s rank in final ranking = 17 + 3 = 20th (3 runners added before Arjun''s new 15th position, Bhavna is after Arjun).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003f', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000003f', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000003f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000040', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a queue, Vikram''s initial position from the left was 10th. After some adjustments, he moved 4 positions to the right. If his new position from the right end of the queue is 12th, what is the total number of people in the queue?', 'MCQ', 'MEDIUM', '{"options": ["21", "23", "25", "26", "27"]}', '25', 'Initial position from left = 10th.
 Moved 4 positions to the right means away from left end.
 New position = 10 + 4 = 14th from the left.
By the given, Total no. of people in a row: Total = (Position from left) +(Position from right) - 1 
 Total = 14 + 12 -1 = 25', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000040');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000040', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000040', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000040');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000041', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a class of students, Mohan is ranked 8th from the top. Sohan is positioned 5 ranks below Mohan. If Sohan is ranked 17th from the bottom, what is the total number of students in the class?', 'MCQ', 'MEDIUM', '{"options": ["20", "27", "29", "31", "30"]}', '29', 'Mohan''s rank from top = 8th.
 Sohan is 5 positions below means further down the ranking.
 Sohan''s rank = 8 + 5 = 13th from the top.
Sohan''s rank from bottom = 17th
Total students = (Sohan''s rank from top + Sohan''s rank from bottom) - 1
Total = (13 + 17) - 1 = 29', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000041');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000041', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000041', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000041');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000042', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. Neha is 8th from the left and 12th from the right in a line. How many people are between Neha and the middle person in a line?', 'MCQ', 'MEDIUM', '{"options": ["6", "5", "1", "3", "2"]}', '1', 'Neha''s position from left = 8th.
 Neha''s position from right = 12th
Total people = (8 + 12) - 1 = 19 
Middle position = (19 + 1)/2 = 10th
People between Neha (8th) and middle (10th) = 10 - 8 - 1 = 1', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000042');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000042', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000042', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000042');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000043', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. Anita is 7th from the left and 9th from the right in a row. How many people are there in total?', 'MCQ', 'EASY', '{"options": ["14", "15", "16", "17", "18"]}', '15', 'Using formula: Total = Left Rank + Right Rank - 1.
 Total = 7 + 9 - 1 = 15 people in total.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000043');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000043', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000043', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000043');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000044', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a class of 25 students, Ravi is 11th from the left. What is his rank from the right?', 'MCQ', 'EASY', '{"options": ["13th", "14th", "15th", "16th", "17th"]}', '15th', 'Using formula: Right Rank = Total - Left Rank + 1.
 Right Rank = 25 - 11 + 1 = 15th from the right.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000044');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000044', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000044', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000044');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000045', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a class ranking by marks: Rani''s rank is 15th from the top and 18th from the bottom. If 4 students are removed from the class (not including Rani), what will be Rani''s rank from the bottom in the modified class?', 'MCQ', 'HARD', '{"options": ["13th", "14th", "15th", "16th", "17th"]}', '14th', 'Initial: Rani 15th from top, 18th from bottom.
 Total = 15 + 18 - 1 = 32.
 After removing 4 students, total = 28.
 Rani''s top rank remains 15th.
 New bottom rank = 28 - 15 + 1 = 14th from bottom.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000045');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000045', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000045', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000045');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000046', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. Geeta''s position from the top is 12th and from the bottom is 8th. Find the total number of students in the class.', 'MCQ', 'EASY', '{"options": ["18", "19", "20", "21", "22"]}', '19', 'Using formula: Total = Top Rank + Bottom Rank - 1.
 Total = 12 + 8 - 1 = 19 students in the class.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000046');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000046', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000046', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000046');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000047', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row of 20 people, Rajesh is 8th from the left end. Find his position from the right end.', 'MCQ', 'EASY', '{"options": ["12th", "13th", "14th", "15th", "16th"]}', '13th', 'Using formula: Right Rank = Total - Left Rank + 1.
 Right Rank = 20 - 8 + 1 = 13th from the right end.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000047');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000047', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000047', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000047');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000048', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a line of students, Ramesh is 7th from the left. Suresh is 5th from the right. If Ramesh and Suresh are separated by 4 students, how many students are there in total?', 'MCQ', 'MEDIUM', '{"options": ["15", "16", "17", "18", "Cannot be determined"]}', '16', 'Ramesh''s position from the left = 7
Suresh''s position from the right = 5
Number of students between them = 4
Step 1: Total students = Ramesh''s position from left + Suresh''s position from right + students in between = 7 + 5 + 4 = 16.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000048');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000048', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000048', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000048');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000049', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row of 40 people, Ajay is 16th from the left end, and Vijay is 14th from the right end. How many people are between Ajay and Vijay?', 'MCQ', 'HARD', '{"options": ["3", "5", "7", "9", "10"]}', '10', 'Total people = 40
Ajay''s position from left = 16th
Vijay''s position from right = 14th
Vijay''s position from left = 40 - 14 + 1 = 27th
People between Ajay (16th) and Vijay (27th) = 27 - 16 - 1 = 10', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000049');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000049', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000049', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000049');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004a', 'dddddddd-dddd-dddd-dddd-000000000005', 'Study the following information carefully and answer the question given below. In a row of 40 students, Sameer is 12th from the left. If Sameer and the student who is 28th from the left exchange their positions, what will be Sameer''s rank from the right after the exchange?', 'MCQ', 'HARD', '{"options": ["11th", "12th", "13th", "14th", "15th"]}', '13th', 'Initial position: Sameer is 12th from left in a row of 40.
 After exchange with 28th position person, Sameer moves to 28th from left.
 New right rank = 40 - 28 + 1 = 13th from the right.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004a', 'eeeeeeee-eeee-eeee-eeee-000000000005', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004a', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004a');

-- Statement and Assumptions -> topic Statement and Assumptions
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000006', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Statement and Assumptions', 'Evaluates arguments by determining which assumptions are implicit in the given statements', 'MEDIUM', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000006');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000006', 'dddddddd-dddd-dddd-dddd-000000000006', 'Statement and Assumptions Challenge', 'Apply statement and assumptions skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000006');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004b', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The bank urges all customers to use ATMs instead of visiting branches.'' Assumptions: I. There is a need to reduce crowding at bank branches. II. Most customers have access to ATMs.', 'MCQ', 'EASY', '{"options": ["Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "Only I or II is implicit"]}', 'Both I and II are implicit', 'The urge assumes (I) there is a problem of overcrowding at branches that needs to be addressed, and (II) customers have the facility to use ATMs.
 Both are logically implicit in the request.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004b', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004b', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004c', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The hospital should implement a strict no-smoking policy within its premises to ensure patient safety.'' Assumptions: I. Smoking poses health risks to patients. II. Hospital staff enforcement will be consistent. III. Visitors will comply with the policy. IV. Secondhand smoke affects patient recovery.', 'MCQ', 'HARD', '{"options": ["I, II, and IV are implicit", "I and IV are implicit", "Only I and II are implicit", "All four are implicit", "I, III, and IV are implicit"]}', 'I and IV are implicit', 'The policy assumes (I) smoking is harmful to patients, and (IV) secondhand smoke affects recovery (both health-related).
 These are core to the ''patient safety'' rationale.
 Assumptions II and III about enforcement and compliance are operational concerns, not implicit justifications for the policy.
 Only I and IV are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004c', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004c', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004d', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Buy our new smartphone and get a 50% discount on screen protector.'' Assumptions: I. Customers value getting additional products at reduced prices. II. Screen protectors are essential for smartphone protection.', 'MCQ', 'EASY', '{"options": ["Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "Only I is implicit, II may be implicit"]}', 'Only I is implicit', 'The advertisement assumes (I) customers find discount offers attractive, which is the basis for the promotional strategy.
 Assumption II introduces a new fact not necessarily implied by the offer.
 Only I is implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004d', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004d', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004e', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Companies should hire more employees instead of relying on automation.'' Assumptions: I. Unemployment is a significant problem. II. Automation reduces job opportunities. III. Human labor is more efficient than automation. IV. Job creation is a corporate responsibility.', 'MCQ', 'HARD', '{"options": ["I, II, and IV are implicit", "I, III, and IV are implicit", "Only I and IV are implicit", "All four are implicit", "Only II and III are implicit"]}', 'I, II, and IV are implicit', 'The statement assumes (I) unemployment is a concern requiring job creation, (II) automation displaces workers, and (IV) companies have responsibility to create jobs.
 Assumption III claiming human labor is ''more efficient'' contradicts the reason for promoting hiring (cost-effectiveness).
 Only I, II, and IV are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004e', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004e', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004f', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The government should implement stricter traffic laws to reduce road accidents.'' Assumptions: I. Current traffic laws are inadequate. II. Stricter laws will discourage rash driving. III. Road accidents can be reduced through legislation.', 'MCQ', 'MEDIUM', '{"options": ["Only I and II are implicit", "Only I and III are implicit", "Only II and III are implicit", "All three are implicit", "Only I is implicit"]}', 'All three are implicit', 'The policy suggestion assumes (I) current laws are insufficient, (II) stricter laws will deter rash driving behavior, and (III) legislative measures can reduce accidents.
 All three assumptions are logically necessary for the statement to be valid.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004f', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000004f', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000004f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000050', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The government should subsidize agricultural products to support farmers and reduce food prices.'' Assumptions: I. Current food prices are unaffordable for the majority. II. Farmers are facing economic hardship. III. Subsidies will not create inflation. IV. Market forces alone cannot balance food prices.', 'MCQ', 'HARD', '{"options": ["I, II, and IV are implicit", "II, III, and IV are implicit", "Only I, II are implicit", "All four are implicit", "Only II and IV are implicit"]}', 'I, II, and IV are implicit', 'The policy assumes (I) food affordability is an issue, (II) farmers need support, and (IV) market mechanisms are insufficient.
 These justify the subsidy proposal.
 Assumption III about preventing inflation is a counter-risk concern, not a supporting assumption.
 Only I, II, and IV are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000050');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000050', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000050', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000050');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000051', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Students should take short breaks while studying to enhance concentration.'' Assumptions: I. Taking breaks can improve focus and learning. II. All students suffer from poor concentration. III. Breaks help prevent mental fatigue.', 'MCQ', 'MEDIUM', '{"options": ["Only I and III are implicit", "Only I and II are implicit", "Only II and III are implicit", "All three are implicit", "Only I is implicit"]}', 'Only I and III are implicit', 'The statement assumes (I) breaks enhance concentration/learning and (III) breaks reduce fatigue.
 Both are implicit.
 Assumption II overgeneralizes by claiming ''all students'' suffer from poor concentration, which is not necessarily implied.
 Only I and III are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000051');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000051', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000051', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000051');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000052', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Universities should reduce tuition fees to make higher education accessible to economically weaker sections.'' Assumptions: I. Current fees exclude economically disadvantaged students. II. Reduced fees will lead to more enrollments. III. Universities can operate with lower revenue. IV. Quality of education depends on tuition amount.', 'MCQ', 'HARD', '{"options": ["I, II, and III are implicit", "I and II are implicit", "II and III are implicit", "All four are implicit", "I, II, III, and IV may be implicit"]}', 'I and II are implicit', 'The statement assumes (I) high fees create barriers for disadvantaged students, (II) lower fees will increase access/enrollment
 Assumption III, IV incorrectly links quality to fees, which contradicts the statement''s intent.
 Only I, and II are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000052');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000052', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000052', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000052');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000053', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''A company announces a work-from-home policy for all employees.'' Assumptions: I. The company trusts its employees'' work ethics. II. Work-from-home improves employee satisfaction. III. All jobs can be performed remotely.', 'MCQ', 'MEDIUM', '{"options": ["Only I and II are implicit", "Only I and III are implicit", "Only II and III are implicit", "All three are implicit", "Only I is implicit"]}', 'Only I and II are implicit', 'The work-from-home policy assumes (I) the company trusts employees to work independently, and (II) it believes this will increase satisfaction or productivity.
 Assumption III overgeneralizes; not all roles can be remote.
 Only I and II are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000053');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000053', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000053', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000053');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000054', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The city should develop more parks and green spaces to combat pollution.'' Assumptions: I. Pollution levels in the city are high. II. Green spaces reduce air pollution. III. Citizens prefer living in polluted areas.', 'MCQ', 'MEDIUM', '{"options": ["Only I and II are implicit", "Only I and III are implicit", "Only II and III are implicit", "All three are implicit", "Only I is implicit"]}', 'Only I and II are implicit', 'The statement assumes (I) pollution is a problem in the city, and (II) green spaces are an effective solution.
 Both are implicit.
 Assumption III contradicts the intent of developing parks (people would prefer non-polluted areas).
 Only I and II are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000054');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000054', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000054', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000054');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000055', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The government should raise taxes on high-income earners to fund public education.'' Assumptions: I. Public education requires increased funding. II. Raising taxes will not discourage economic productivity. III. Wealth redistribution is a valid government function. IV. High earners can afford higher taxes.', 'MCQ', 'HARD', '{"options": ["I, II, and IV are implicit", "I, III, and IV are implicit", "I and IV are implicit", "All four are implicit", "Only I and III are implicit"]}', 'I, III, and IV are implicit', 'The statement assumes (I) education funding is inadequate, (III) wealth redistribution through taxation is acceptable, and (IV) high earners have the capacity to pay more.
 Assumption II about not discouraging productivity is a counter-argument, not an assumption supporting the statement.
 Only I, III, and IV are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000055');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000055', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000055', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000055');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000056', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Do not cross the railway tracks illegally.'' Assumptions: I. Crossing railway tracks illegally is dangerous. II. People often attempt to cross illegally.', 'MCQ', 'EASY', '{"options": ["Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "Only I or II is implicit"]}', 'Both I and II are implicit', 'The warning assumes (I) there is danger/harm in crossing illegally, and (II) people do attempt such crossing (otherwise why warn?).
 Both assumptions are implicit in giving such a warning.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000056');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000056', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000056', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000056');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000057', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''Schools should conduct regular counseling sessions for students.'' Assumptions: I. Students face mental or emotional challenges. II. Counseling can help address student issues. III. All students require counseling.', 'MCQ', 'MEDIUM', '{"options": ["Only I and II are implicit", "Only I and III are implicit", "Only II and III are implicit", "All three are implicit", "Only I is implicit"]}', 'Only I and II are implicit', 'The proposal assumes (I) students have challenges needing support, and (II) counseling is effective.
 Both are implicit.
 Assumption III claiming ''all students require'' counseling is too absolute and not necessarily implied.
 Only I and II are implicit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000057');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000057', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000057', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000057');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000058', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The government should invest in renewable energy sources.'' Assumptions: I. Renewable energy sources are beneficial. II. The government has the capacity to invest in such projects.', 'MCQ', 'EASY', '{"options": ["Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "Only I or II is implicit"]}', 'Both I and II are implicit', 'The statement suggests government investment in renewable energy.
 For this to make sense, it assumes (I) renewable energy has benefits, and (II) the government is capable of investing.
 Both assumptions are logically necessary for the statement to hold true.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000058');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000058', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000058', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000058');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000059', 'dddddddd-dddd-dddd-dddd-000000000006', 'Directions: In the following question, a statement is given followed by certain assumptions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given assumptions can be logically inferred from the statement. Statement: ''The school should introduce computer labs to improve technical skills.'' Assumptions: I. The school currently lacks computer labs. II. Computer labs help develop technical skills.', 'MCQ', 'EASY', '{"options": ["Only I is implicit", "Only II is implicit", "Both I and II are implicit", "Neither I nor II is implicit", "Only I or II is implicit"]}', 'Both I and II are implicit', 'The suggestion assumes (I) computer labs are not currently available, and (II) they are beneficial for skill development.
 Both are logically necessary for the statement''s validity.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000059');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000059', 'eeeeeeee-eeee-eeee-eeee-000000000006', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000059', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000059');

-- Data Sufficiency -> topic Data Sufficiency
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000007', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Data Sufficiency', 'Assesses sufficiency of given data to solve problems involving reasoning or arithmetic', 'MEDIUM', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000007');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000007', 'dddddddd-dddd-dddd-dddd-000000000007', 'Data Sufficiency Challenge', 'Apply data sufficiency skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000007');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005a', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the ratio of boys to girls in a class? Statements: I. There are 30 boys. II. Total students = 50.', 'MCQ', 'MEDIUM', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I alone: Only boys count, no girls data.
 Statement II alone: Total but no breakdown.
 Together: Boys = 30, Girls = 50 - 30 = 20.
 Ratio = 30:20 = 3:2.
 Both statements together are sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005a', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005a', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005b', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the direction of D with respect to A? Statements: I. A is to the west of B. II. D is to the north of B.', 'MCQ', 'MEDIUM', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I: A is west of B.
 Statement II: D is north of B.
 Using B as reference point: A is west, D is north.
 Therefore, D is to the northeast of A.
 Both statements together are necessary and sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005b', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005b', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005c', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the average of M, N, and O? Statements: I. M + N + O = 90. II. M = 30, N = 30, O = 30.', 'MCQ', 'HARD', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Either statement I or II alone is sufficient', 'Statement I: Sum = 90 → Average = 90/3 = 30.
 Statement II: All values given → Average = 30.
 Either statement alone is sufficient to find average = 30.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005c', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005c', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005d', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. How many students scored more than 70 marks? Statements: I. Out of 100 students, 60% scored above 70. II. 60 students scored above 70 marks.', 'MCQ', 'HARD', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Either statement I or II alone is sufficient', 'Statement I: 60% of 100 = 60 students.
 Statement II: 60 students directly.
 Either statement alone provides the answer: 60 students scored more than 70 marks.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005d', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005d', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005e', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. Who is taller — X or Y? Statements: I. X is taller than Z. II. Y is taller than Z.', 'MCQ', 'MEDIUM', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Statements I and II together are not sufficient', 'Statement I: X > Z.
 Statement II: Y > Z.
 Both only relate X and Y to Z separately.
 Cannot determine direct comparison between X and Y.
 Both statements together are insufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005e', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005e', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005f', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. Who is the eldest among A, B, and C? Statements: I. A is older than B and C. II. C is the youngest.', 'MCQ', 'EASY', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Statement I alone is sufficient', 'Statement I clearly states A is older than both B and C, making A the eldest.
 Statement I alone is sufficient.
 Statement II only tells us C is youngest, not who is eldest.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005f', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000005f', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000005f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000060', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the order of A, B, C, D from youngest to oldest? Statements: I. A is older than B but younger than C. II. D is older than C.', 'MCQ', 'HARD', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I: B < A < C.
 Statement II: C < D.
 Combined: B < A < C < D.
 Order from youngest to oldest is clear.
 Both statements together are necessary and sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000060');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000060', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000060', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000060');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000061', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. Is A taller than B? Statements: I. A is 180 cm. II. B is 170 cm.', 'MCQ', 'EASY', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I alone doesn''t tell us B''s height.
 Statement II alone doesn''t tell us A''s height.
 Together: A (180 cm) > B (170 cm), so A is taller.
 Both statements together are sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000061');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000061', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000061', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000061');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000062', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. Who sits between X and Y in a row? Statements: I. A sits to the right of X. II. Y sits to the left of A. III. B sits to the right of Y.', 'MCQ', 'HARD', '{"options": ["Statement I alone is sufficient", "Statements I and II together are sufficient", "Statements I, II, and III together are sufficient", "All three statements individually are insufficient but together sufficient", "Even all three together are insufficient"]}', 'Even all three together are insufficient', 'From I: X ... A (A is right of X).
 From II: Y ... A (Y is left of A).
From III: Y ... B (B is right of Y). These only fix relative positions with respect to A and Y; they do not fix the ordering of X and Y (or whether someone sits between them). Hence the statements (alone or together) are insufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000062');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000062', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000062', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000062');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000063', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the total salary of Aman? Statements: I. Aman earns ₹50,000 per month. II. Aman''s annual salary is ₹6,00,000.', 'MCQ', 'EASY', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Either statement I or II alone is sufficient', 'Statement I: Monthly ₹50,000 → Annual = ₹6,00,000.
 Statement II: Annual = ₹6,00,000.
 Either statement alone is sufficient to find total annual salary.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000063');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000063', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000063', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000063');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000064', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the value of (a + b)? Statements: I. a is 20% more than b. II. b = 50.', 'MCQ', 'HARD', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I: a = 1.2b (relationship).
 Statement II: b = 50 (value).
 Together: a = 1.2(50) = 60, so a + b = 110.
 Both statements together are sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000064');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000064', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000064', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000064');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000065', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the age of Rajesh? Statements: I. Rajesh is 5 years older than Priya. II. Priya is 20 years old.', 'MCQ', 'EASY', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Both statements I and II together are sufficient', 'Statement I tells the relationship but not Rajesh''s actual age.
 Statement II gives Priya''s age.
 Combined: Rajesh = 20 + 5 = 25 years.
 Both statements together are necessary and sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000065');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000065', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000065', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000065');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000066', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. Among P, Q, R, and S, who is the shortest? Statements: I. P is taller than Q but shorter than R. II. S is the shortest.', 'MCQ', 'MEDIUM', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Statement II alone is sufficient', 'Statement I gives relationship among P, Q, R but not S''s comparison.
 Statement II directly states S is shortest.
 Statement II alone is sufficient to answer the question.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000066');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000066', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000066', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000066');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000067', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is the value of x? Statements: I. x + 10 = 25. II. 2x = 30.', 'MCQ', 'EASY', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Either statement I or II alone is sufficient', 'Statement I: x + 10 = 25 → x = 15.
 Statement II: 2x = 30 → x = 15.
 Either statement alone is sufficient to find x = 15.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000067');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000067', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000067', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000067');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000068', 'dddddddd-dddd-dddd-dddd-000000000007', 'Directions: In the following question, a question is followed by certain statements. You have to decide which statement(s) alone or together are sufficient to answer the question. What is 25% of a number? Statements: I. The number is 100. II. 50% of the number is 50.', 'MCQ', 'MEDIUM', '{"options": ["Statement I alone is sufficient", "Statement II alone is sufficient", "Either statement I or II alone is sufficient", "Both statements I and II together are sufficient", "Statements I and II together are not sufficient"]}', 'Either statement I or II alone is sufficient', 'Statement I: Number = 100 → 25% = 25.
 Statement II: 50% = 50 → Number = 100 → 25% = 25.
 Either statement alone is sufficient.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000068');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000068', 'eeeeeeee-eeee-eeee-eeee-000000000007', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000068', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000068');

-- Statement and Arguments -> topic Statement and Arguments
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000008', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Statement and Arguments', 'Tests reasoning by analyzing which arguments logically follow statements', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000008');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000008', 'dddddddd-dddd-dddd-dddd-000000000008', 'Statement and Arguments Challenge', 'Apply statement and arguments skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000008');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000069', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and evaluate both the classification and strength of arguments. Statement: Should developing nations prioritize renewable energy over coal-based power generation? Arguments: I. Yes, renewable energy prevents climate change, reduces pollution-related health costs, and provides long-term energy independence without depleting resources. II. No, coal-based power is cheaper initially and can provide immediate electricity to growing populations, while renewable infrastructure requires large upfront investment.', 'MCQ', 'HARD', '{"options": ["I is positive and strong; II is negative and strong", "I is positive and weak; II is negative and weak", "I is positive and strong; II is negative and weak", "Both are positive and equally strong", "Both are negative and weak"]}', 'I is positive and strong; II is negative and strong', 'Argument I is positive (supports the statement) and strong because it provides multiple logical benefits—climate protection, health improvements, resource sustainability, and energy independence.
Argument II is negative (opposes the statement) and strong because it identifies a real practical constraint faced by developing nations—immediate cost considerations and energy demands versus long-term sustainability.
Both arguments are based on sound reasoning about different priorities, making them both strong despite representing competing development strategies.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000069');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000069', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000069', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000069');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006a', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate the logical validity and practical feasibility of each argument. Statement: Should parenthood licensing be implemented, requiring couples to pass competency tests before having children? Arguments: I. Yes, parenthood licensing would ensure children receive proper care, education, and upbringing, reducing child abuse and neglect cases significantly. II. No, such a system is ethically problematic, violates reproductive freedom, and is practically impossible to enforce fairly across diverse cultural contexts.', 'MCQ', 'HARD', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is ethical"]}', 'Both Arguments are strong', 'Argument I is strong because it identifies a logical benefit—improving child welfare outcomes through ensuring parental competency.
Argument II is strong because it raises multiple valid concerns—ethical principles regarding reproductive freedom, implementation challenges across cultural diversity, and the enforcement feasibility of such a system.
Both arguments are logically sound, making this a complex issue where genuine tensions exist between child welfare and individual liberty, requiring careful consideration of both positions.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006a', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006a', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006b', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate the arguments. Statement: Should higher education be made free for all citizens? Arguments: I. Yes, education is a fundamental right and should be accessible to everyone regardless of economic status. II. No, it is too expensive and will burden the government''s budget.', 'MCQ', 'EASY', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is logical"]}', 'Both Arguments are strong', 'Argument I is strong because it presents a principled reason based on the concept of rights and social equality.
Argument II is strong because it addresses practical economic feasibility and government resource constraints.
Both arguments are logically valid—one prioritizes social equity, the other considers economic reality.
These are opposing but equally strong arguments, making both valid positions on this complex policy issue.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006b', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006b', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006c', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and determine which arguments substantively engage with the core policy question. Statement: Should advanced countries provide unconditional financial aid to developing nations? Arguments: I. Yes, unconditional aid addresses structural inequalities, promotes global stability, and reflects shared human responsibility to reduce extreme poverty and suffering. II. No, unconditional aid discourages recipient nations from developing domestic revenue systems and makes them dependent on donor countries.', 'MCQ', 'HARD', '{"options": ["Only Argument I is relevant", "Only Argument II is relevant", "Both are equally relevant", "Neither is relevant", "Cannot determine"]}', 'Both are equally relevant', 'Both arguments are strong because they address valid, distinct dimensions of the issue: humanitarian responsibility (Argument I) and long-term economic sustainability (Argument II).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006c', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006c', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006d', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and determine which arguments are directly relevant to the issue raised. Statement: Should India encourage more foreign direct investment (FDI)? Arguments: I. Yes, FDI brings capital, creates employment opportunities, and facilitates technology transfer. II. No, my cousin works for a foreign company and faces work pressure.', 'MCQ', 'MEDIUM', '{"options": ["Only Argument I is relevant", "Only Argument II is relevant", "Both are equally relevant", "Neither is relevant", "Cannot determine"]}', 'Only Argument I is relevant', 'Argument I is relevant because it directly addresses the policy question with concrete economic benefits that affect the nation as a whole—capital generation, job creation, and technological advancement.
Argument II is irrelevant because it relies on individual personal experience and anecdotal evidence rather than addressing the broader national or economic implications of FDI.
Individual work experiences cannot determine national-level policy decisions, making this argument off-topic to the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006d', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006d', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006e', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate which arguments are strong. Statement: Should voting be made compulsory for all eligible citizens? Arguments: I. Yes, compulsory voting ensures greater political participation and stronger democratic representation. II. No, forcing citizens to vote violates individual freedom and democratic principles.', 'MCQ', 'MEDIUM', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is relevant"]}', 'Both Arguments are strong', 'Argument I is strong because it provides a logical benefit—increased voter participation leads to more representative outcomes and better democratic functioning.
Argument II is strong because it raises a valid philosophical concern about individual liberty and democratic freedom.
Both arguments are logically sound and based on reasoning—one emphasizes democratic outcomes, the other emphasizes democratic principles.
This represents a genuine tension between competing values, making both arguments strong despite their opposition.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006e', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006e', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006f', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and classify the arguments as positive or negative, and evaluate their strength. Statement: Should the government impose heavy taxes on luxury goods? Arguments: I. Yes, luxury taxation can reduce wealth inequality and generate substantial revenue for social welfare programs. II. No, high taxes on luxury goods will discourage industrial growth and investment in manufacturing.', 'MCQ', 'MEDIUM', '{"options": ["I is positive and strong; II is negative and weak", "I is positive and weak; II is negative and strong", "Both are positive and strong", "Both are negative and weak", "I is positive and strong; II is negative and strong"]}', 'I is positive and strong; II is negative and strong', 'Argument I is positive (supports the statement) and strong because it presents logical economic and social benefits—reducing inequality and funding welfare programs.
Argument II is negative (opposes the statement) and strong because it raises a valid economic concern—taxation policies do affect investment and industrial expansion.
Both arguments address real economic consequences and are logically reasoned, making them both strong positions on this complex economic issue.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006f', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000006f', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000006f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000070', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate which of the given arguments is strong or weak. Statement: Should plastic bags be completely banned? Arguments: I. Yes, plastic bags cause severe environmental pollution and take hundreds of years to decompose. II. No, people like using plastic bags because they are convenient.', 'MCQ', 'EASY', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is relevant"]}', 'Only Argument I is strong', 'Argument I is strong because it is based on factual and logical reasoning—plastic bags do cause environmental pollution and take a very long time to decompose, which affects the ecosystem.
Argument II is weak because it relies on personal convenience and subjective preference rather than addressing the core issue of environmental impact.
Personal convenience cannot outweigh environmental concerns, making it an emotionally appealing but logically weak argument.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000070');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000070', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000070', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000070');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000071', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and determine which arguments directly address the core issue. Statement: Should examinations be conducted online instead of offline in universities? Arguments: I. Yes, online examinations reduce infrastructure costs, prevent cheating through digital surveillance, and are accessible to students in remote areas. II. No, online examinations are unfair because some students have better internet connectivity than others.', 'MCQ', 'MEDIUM', '{"options": ["Only Argument I is relevant", "Only Argument II is relevant", "Both are equally relevant", "Neither is relevant", "Cannot determine"]}', 'Both are equally relevant', 'Argument I is relevant because it directly addresses practical benefits of online examinations—cost reduction, cheating prevention, and accessibility.
Argument II is also relevant because it identifies a genuine implementation challenge—the digital divide and unequal access to technology.
Both arguments directly engage with the core question about shifting to online examinations and present different but valid concerns about the proposal''s effectiveness and fairness.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000071');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000071', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000071', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000071');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000072', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and evaluate the arguments. Statement: Should there be a complete ban on single-use plastics? Arguments: I. Yes, single-use plastics accumulate in landfills and oceans, harming marine life and polluting the environment irreversibly. II. No, single-use plastics are inexpensive and convenient for everyday use by common people.', 'MCQ', 'MEDIUM', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is practical"]}', 'Only Argument I is strong', 'Argument I is strong because it presents factual, evidence-based reasoning about environmental harm caused by single-use plastics—accumulation in ecosystems and damage to marine life are documented consequences.
Argument II is weak because it prioritizes personal convenience over environmental consequences.
While convenience matters, it cannot logically outweigh irreversible environmental damage, making this argument emotionally appealing but rationally weaker than the environmental concerns.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000072');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000072', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000072', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000072');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000073', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate the logical strength and validity of each argument. Statement: Should artificial intelligence be regulated strictly by governments worldwide? Arguments: I. Yes, strict regulation ensures ethical AI development, protects privacy, and prevents misuse of AI for surveillance or manipulation. II. No, strict regulations will stifle innovation, make companies uncompetitive globally, and push development to unregulated jurisdictions.', 'MCQ', 'HARD', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Only Argument I is practical"]}', 'Both Arguments are strong', 'Argument I is strong because it identifies genuine risks that require governance—ethical concerns, privacy protection, and prevention of harmful applications are legitimate policy objectives.
Argument II is strong because it raises a valid concern about unintended consequences—excessive regulation can drive innovation elsewhere and reduce competitiveness without achieving safety goals.
Both arguments are logically sound and address real trade-offs between safety and innovation.
This represents a complex policy question where both positions have merit, making both arguments strong.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000073');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000073', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000073', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000073');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000074', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement carefully and evaluate the strength of the given arguments. Statement: Should examinations be abolished in schools? Arguments: I. Yes, examinations cause unnecessary stress to students. II. No, examinations help assess learning progress and maintain academic standards.', 'MCQ', 'EASY', '{"options": ["Only Argument I is strong", "Only Argument II is strong", "Both Arguments are strong", "Neither argument is strong", "Cannot be determined"]}', 'Only Argument II is strong', 'Argument I is weak as it focuses on the emotional side effect (stress) rather than addressing whether examinations serve a purpose.
Argument II is strong because it provides logical reasons why examinations are necessary—they serve a concrete function in evaluating student learning and maintaining educational quality.
The purpose and necessity of examinations override concerns about temporary stress, making Argument II the stronger position.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000074');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000074', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000074', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000074');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000075', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and carefully determine which arguments are directly pertinent to the issue. Statement: Should gig economy workers (freelancers, delivery personnel) be provided formal employment benefits? Arguments: I. Yes, gig workers lack job security, health insurance, and retirement benefits, making formal recognition necessary for their financial protection and social security. II. No, gig workers are happy to work independently because they dislike office environments.', 'MCQ', 'HARD', '{"options": ["Only Argument I is relevant", "Only Argument II is relevant", "Both are equally relevant", "Neither is relevant", "Only Argument II is irrelevant"]}', 'Only Argument I is relevant', 'Argument I is relevant because it directly addresses a policy question about worker protections and identifies concrete issues—lack of job security, health insurance, and retirement benefits.
Argument II is irrelevant because it relies on generalized assumptions about worker preferences rather than addressing the actual needs for social protection and financial security.
Individual work preference do not address the systemic gaps in worker protection that the statement raises, making this argument off-topic.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000075');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000075', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000075', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000075');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000076', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and determine which argument is relevant to the issue. Statement: Should school uniforms be made mandatory for all students? Arguments: I. Yes, uniforms promote equality among students and reduce socioeconomic disparities. II. No, students in my neighborhood prefer wearing colorful clothes.', 'MCQ', 'EASY', '{"options": ["Only Argument I is relevant", "Only Argument II is relevant", "Both are equally relevant", "Neither is relevant", "Cannot determine"]}', 'Only Argument I is relevant', 'Argument I is relevant because it directly addresses the core issue of uniforms and provides a logical benefit (promoting equality and reducing disparities).
Argument II is irrelevant because it is based on personal observation and individual preference rather than addressing the actual impact or necessity of uniforms.
Personal choices cannot justify a policy decision affecting entire schools, making this argument off-topic and irrelevant to the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000076');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000076', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000076', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000076');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000077', 'dddddddd-dddd-dddd-dddd-000000000008', 'Read the statement and identify which argument supports and which opposes it, and evaluate their strength. Statement: Should sports be made compulsory in all schools? Arguments: I. Yes, sports improve physical health, discipline, and mental well-being among students. II. No, sports activities will divert attention from core academic studies.', 'MCQ', 'EASY', '{"options": ["Argument I is positive and strong; Argument II is negative and strong", "Argument I is positive and weak; Argument II is negative and weak", "Argument I is positive and strong; Argument II is negative and weak", "Argument I is positive and weak; Argument II is negative and strong", "Cannot be determined"]}', 'Argument I is positive and strong; Argument II is negative and strong', 'Argument I is positive (supports the statement) and strong because physical health, discipline, and mental well-being are well-established benefits of sports participation.
Argument II is negative (opposes the statement) and also strong because it raises a valid concern—sports do require time that could otherwise be spent on academics.
Both arguments are logically sound and address real considerations, making them both strong despite opposing each other.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000077');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000077', 'eeeeeeee-eeee-eeee-eeee-000000000008', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000077', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000077');

-- Cause and Effect -> topic Cause and Effect
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000009', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Cause and Effect', 'Identifies relationships between events to determine which is cause and which is effect', 'MEDIUM', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000009');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000009', 'dddddddd-dddd-dddd-dddd-000000000009', 'Cause and Effect Challenge', 'Apply cause and effect skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000009');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000078', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The hospital received an increased number of patients. Statement II: The clinic had to increase its staff.', 'MCQ', 'MEDIUM', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement I is the cause and Statement II is the effect', 'Increased patient numbers (Statement I) directly caused the clinic to hire more staff (Statement II).
 More patients is the cause; increased staffing is the effect needed to handle the increased workload.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000078');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000078', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000078', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000078');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000079', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Power supply was disrupted in many areas of the city. Statement II: Heavy storms damaged power transmission lines in the region.', 'MCQ', 'HARD', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'Storm damage to transmission lines (Statement II) directly caused power disruption (Statement I).
 Physical infrastructure damage is the cause; loss of electricity supply is the direct consequence or effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000079');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000079', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000079', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000079');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007a', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Students are using online study materials frequently. Statement II: Internet connectivity in schools has been upgraded recently.', 'MCQ', 'EASY', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'Upgraded internet connectivity (Statement II) enables students to use online materials more frequently (Statement I).
 The improved connectivity is the cause; increased usage is the effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007a', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007a', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007b', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The price of gold increased significantly in international markets. Statement II: The rupee weakened against the US dollar.', 'MCQ', 'HARD', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Both are effects of a common cause', 'Both statements are effects of a common cause: global economic instability or inflation concerns.
 Gold price increases and currency weakness both result from underlying market conditions, not from each other.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007b', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007b', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007c', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The government introduced new taxation rules. Statement II: The local sports team won the national championship.', 'MCQ', 'EASY', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Both are independent and have no causal relation', 'Taxation rules and sports championship are completely unrelated events.
 There is no logical cause-effect connection between government policy and a sports team''s performance.
 These are independent events.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007c', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007c', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007d', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Several flights were cancelled from the airport. Statement II: There was heavy snowfall in the hilly region where the airport is located.', 'MCQ', 'HARD', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'Heavy snowfall (Statement II) caused poor visibility and runway conditions, leading to flight cancellations (Statement I).
 Adverse weather is the cause; operational disruptions are the effect resulting from weather conditions.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007d', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007d', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007e', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Students are carrying umbrellas to school. Statement II: People are wearing raincoats and water-resistant clothing.', 'MCQ', 'MEDIUM', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Both are effects of a common cause', 'Both statements are effects resulting from a common cause: rainfall or monsoon season.
 Neither statement causes the other; both are independent reactions to the same environmental condition (weather).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007e', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007e', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007f', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Many employees resigned from the organization last month. Statement II: The company failed to provide promised salary increments and career growth opportunities.', 'MCQ', 'HARD', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'Unmet promises regarding salary and growth (Statement II) caused employee resignations (Statement I).
 Unfulfilled employee expectations are the root cause; resignations are the resulting effect reflecting employee dissatisfaction and departure.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007f', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000007f', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000007f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000080', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The ground is wet. Statement II: It rained heavily last night.', 'MCQ', 'EASY', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'Rain (Statement II) is the cause that led to the ground becoming wet (Statement I).
 The effect (wet ground) is a direct result of the cause (rainfall).
 Time sequence: Rain happened first, then the ground became wet.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000080');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000080', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000080', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000080');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000081', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Many people suffered from dehydration during the event. Statement II: Several cases of heat-related illnesses were reported.', 'MCQ', 'MEDIUM', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Both are effects of a common cause', 'Both statements are effects of a common cause: extreme heat and inadequate water supply at the event.
 Dehydration and heat illness are independent problems resulting from the same underlying cause (extreme conditions).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000081');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000081', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000081', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000081');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000082', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The stock market fell sharply yesterday. Statement II: Investors became nervous and withdrew their money.', 'MCQ', 'MEDIUM', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement I is the cause and Statement II is the effect', 'Market crash (Statement I) caused investor panic and withdrawals (Statement II).
 The falling market is the cause that triggered nervousness and money withdrawal as the effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000082');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000082', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000082', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000082');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000083', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Sales of air conditioners increased significantly. Statement II: The temperature this summer was unusually high.', 'MCQ', 'EASY', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'High temperature (Statement II) causes people to buy more air conditioners (Statement I).
 The unusual heat is the cause leading to increased AC sales as the effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000083');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000083', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000083', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000083');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000084', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The company''s quarterly profits declined significantly. Statement II: The marketing team received reduced budget allocation.', 'MCQ', 'HARD', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement I is the cause and Statement II is the effect', 'Declining profits (Statement I) forced management to reduce the marketing budget (Statement II).
 Lower profitability is the cause; budget reduction is the cost-control effect implemented in response.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000084');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000084', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000084', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000084');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000085', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: Air pollution levels increased in the city. Statement II: The number of vehicles on roads increased.', 'MCQ', 'EASY', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement II is the cause and Statement I is the effect', 'More vehicles on roads (Statement II) produce more emissions, causing increased pollution (Statement I).
 Increased vehicle traffic is the cause; increased pollution is the direct effect of this cause.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000085');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000085', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000085', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000085');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000086', 'dddddddd-dddd-dddd-dddd-000000000009', 'Directions: In the following question, two statements are given. You have to decide which statement is the cause and which is the effect, or whether both are independent or related in some other way. Statement I: The government increased import duties on oil. Statement II: Petrol prices rose in the domestic market.', 'MCQ', 'MEDIUM', '{"options": ["Statement I is the cause and Statement II is the effect", "Statement II is the cause and Statement I is the effect", "Both are independent causes of a common effect", "Both are effects of a common cause", "Both are independent and have no causal relation"]}', 'Statement I is the cause and Statement II is the effect', 'Import duty increase (Statement I) makes imported oil more expensive, directly causing domestic petrol prices to rise (Statement II).
 Policy change is the cause; price increase is the resulting effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000086');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000086', 'eeeeeeee-eeee-eeee-eeee-000000000009', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000086', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000086');

-- Statement and Courses of Action -> topic Statement and Courses of Action
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000a', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Statement and Courses of Action', 'Focuses on evaluating a given situation and determining the most logical, practical, and appropriate actions to address the issue effectively.', 'MEDIUM', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000a');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Statement and Courses of Action Challenge', 'Apply statement and courses of action skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000087', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and identify which courses of action are appropriate responses to address systemic problems. Statement: Corruption in educational institutions has compromised the quality of education, affected student merit, and damaged public trust in academic credentials and institutional integrity. Courses of Action: I. Establish independent oversight committees and implement transparent examination and admission processes with digital tracking systems. II. Close all educational institutions and ban higher education until corruption is completely eliminated.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and constructive because transparent processes, independent oversight, and digital tracking create accountability and prevent corrupt practices.
These measures are implementable and restore institutional integrity progressively.
Course II is extremely impractical because closing all institutions would destroy the education system and harm millions of students.
Corruption cannot be eliminated by shutting down the system; it requires systemic reform.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000087');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000087', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000087', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000087');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000088', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and determine which course(s) of action are appropriate. Statement: Cybercrime and online fraud cases have increased significantly, especially targeting senior citizens and small business owners. Courses of Action: I. The government should strengthen cyber laws and ensure strict punishment for offenders. II. Citizens should completely stop using online payment systems and digital platforms.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and necessary because stronger cyber laws and enforcement directly combat cybercrime.
This is a feasible measure that addresses the root cause through legal deterrence.
Course II is impractical and extreme because stopping all online activities is unrealistic in the modern world.
Citizens need digital platforms for essential services, making this action counterproductive.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000088');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000088', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000088', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000088');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000089', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement carefully and evaluate which courses of action are both necessary and complementary in addressing this complex issue. Statement: Climate change is causing frequent natural disasters, agricultural failures, and mass migration in vulnerable regions, while affected communities lack disaster preparedness, early warning systems, and livelihood alternatives. Courses of Action: I. Invest in climate-resilient agriculture, early warning systems, and community disaster management training. II. Provide livelihood diversification programs and financial support to help communities adapt to climate impacts.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Both I and II follow', 'Course I is logical and necessary because early warning systems and disaster management training directly reduce loss of life and property.
Climate-resilient agriculture helps maintain food security despite climate challenges.
These are preventive and adaptive measures.
Course II is equally important because livelihood diversification reduces vulnerability to agricultural failures and provides economic stability.
Financial support enables communities to implement adaptation strategies.
Both actions are complementary—Course I addresses immediate disaster response and agricultural resilience, while Course II addresses long-term economic adaptation.
Together, they provide comprehensive climate resilience, making both courses essential and logically following from the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000089');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000089', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000089', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000089');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008a', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement carefully and identify which course of action should be prioritized. Statement: High dropout rates among girls in rural schools are affecting their education and future opportunities, while schools lack infrastructure and teachers are untrained in inclusive education. Courses of Action: I. Improve school infrastructure and provide separate facilities for girls. II. Conduct teacher training programs on inclusive and gender-sensitive education.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Both I and II follow', 'Course I is important because better infrastructure and separate facilities address practical barriers to girls'' attendance and safety.
This course is necessary and feasible.
Course II is equally important because trained teachers create a supportive educational environment that values girls'' education.
Teacher sensitivity directly impacts retention and learning quality.
Both actions complement each other and address different aspects of the problem—infrastructure and human resource development.
Therefore, both courses logically follow and should be implemented together.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008a', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008a', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008b', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and determine which courses of action are logical responses. Statement: Unemployment among youth has risen significantly due to lack of relevant skills and limited job opportunities in the market. Courses of Action: I. The government should establish skill development and vocational training centers. II. Unemployed individuals should be given free money without conditions.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and constructive because it addresses the root cause—lack of relevant skills.
Skill development and vocational training make youth employment-ready and increase their job prospects.
This is feasible, development-oriented, and sustainable.
Course II is impractical and counterproductive because free money without conditions creates dependency and does not solve the underlying employment issue.
It is not a sustainable solution to unemployment.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008b', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008b', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008c', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement carefully and identify which course(s) of action logically follow from the given situation. Statement: Increasing road accidents have become a major problem in the city due to rash driving and traffic violations. Courses of Action: I. The police should enforce traffic rules strictly and conduct regular checkpoints. II. The number of vehicles in the city should be reduced completely.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot be determined"]}', 'Only I follows', 'Course I is logical and feasible because strict enforcement of traffic rules directly addresses the problem of rash driving and violations.
Police checkpoints are practical measures that can be implemented immediately and will have a preventive effect.
Course II is impractical and extreme because reducing vehicles completely is unrealistic and would disrupt city life.
Therefore, only Course I logically follows from the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008c', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008c', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008d', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and identify which course(s) of action are appropriate and practical. Statement: Water scarcity is affecting agricultural productivity in drought-prone regions, causing economic distress to farmers and food insecurity. Courses of Action: I. Promote and subsidize rainwater harvesting and modern irrigation techniques in rural areas. II. Stop all agricultural activities in drought-prone regions permanently.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and feasible because it directly addresses water scarcity through practical solutions like rainwater harvesting and efficient irrigation.
This helps maintain agricultural productivity while solving the water problem sustainably.
Course II is extreme and illogical because stopping agriculture permanently would cause economic collapse in farming communities.
It ignores the possibility of solving the problem through better resource management.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008d', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008d', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008e', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and determine which courses of action are appropriate responses. Statement: Traffic congestion has become severe in metropolitan areas, leading to increased travel time, pollution, and reduced productivity. Courses of Action: I. Expand and improve public transportation systems with better connectivity and frequency. II. Impose immediate ban on private vehicle registration to reduce traffic.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and constructive because improving public transport encourages citizens to shift from private vehicles.
Better connectivity and frequency make public transport attractive and practical, reducing congestion progressively.
Course II is extreme and impractical because banning vehicle registration completely is unrealistic and affects people''s mobility unnecessarily.
This is an overreaction that ignores other viable solutions.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008e', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008e', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008f', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and determine which course of action is a logical response to the problem. Statement: Many students in schools are failing because they lack access to quality teaching and study materials. Courses of Action: I. Schools should hire qualified teachers and provide better study resources. II. Students who fail should be permanently expelled from school.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and constructive because it directly addresses the root cause—lack of quality teaching and materials.
Providing qualified teachers and study resources is a feasible and development-oriented solution.
Course II is illogical and harmful because expulsion punishes students without solving the underlying problem.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008f', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000008f', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000008f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000090', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and evaluate which courses of action are logical and feasible. Statement: Food adulteration and contamination cases have increased, affecting public health and consumer confidence in food products. Courses of Action: I. Food regulatory authorities should conduct surprise inspections and enforce strict food safety standards. II. Implement consumer awareness programs about identifying contaminated food and reporting mechanisms.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Both I and II follow', 'Course I is logical and necessary because surprise inspections and strict enforcement directly target the problem by monitoring food quality.
This is a preventive measure that ensures compliance with food safety standards.
Course II is equally important because consumer awareness empowers citizens to identify contaminated food and report violations.
Informed consumers are partners in maintaining food safety.
Both actions complement each other—enforcement at producer level and awareness at consumer level.
Therefore, both courses logically follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000090');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000090', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000090', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000090');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000091', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and evaluate which courses of action are appropriate responses. Statement: Pollution levels in the city have risen significantly, causing health concerns among residents. Courses of Action: I. The government should promote the use of public transport to reduce vehicle emissions. II. Environmental awareness campaigns should be conducted to educate citizens about pollution control.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Both I and II follow', 'Course I is logical and feasible because public transport reduces individual vehicle emissions, directly tackling pollution.
Course II is also logical because environmental awareness helps citizens make pollution-conscious decisions.
Both actions are constructive, preventive, and complement each other.
They address the problem from different but equally valid perspectives—infrastructure and behavior change.
Therefore, both courses of action logically follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000091');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000091', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000091', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000091');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000092', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement carefully and identify which course(s) of action logically follow, considering complexity and feasibility. Statement: Rapid urbanization has led to inadequate housing, poor sanitation, slum expansion, and health emergencies in cities, while municipal resources are limited and planning capacity is weak. Courses of Action: I. Implement comprehensive urban planning with affordable housing projects and improved sanitation infrastructure. II. Halt all urban migration through strict policy restrictions to control city growth.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and necessary because it directly addresses the problems of inadequate housing and poor sanitation through constructive urban development.
Comprehensive planning and affordable housing are realistic long-term solutions that improve city livability.
Course II is illogical and impractical because restricting migration violates rights and ignores the economic reasons driving urbanization.
Population movement cannot be stopped through restrictions alone.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000092');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000092', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000092', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000092');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000093', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and identify which course of action is practical and appropriate. Statement: Several train accidents have been reported recently due to maintenance negligence and inadequate safety protocols. Courses of Action: I. Railway authorities should conduct regular safety audits and implement stricter maintenance schedules. II. All trains should be stopped immediately until safety measures are 100% perfect.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and feasible because it is a preventive, constructive measure that addresses the problem directly.
Regular safety audits and maintenance schedules are realistic and implementable without disrupting essential services.
Course II is extreme and impractical because stopping all trains indefinitely is unrealistic and would harm the economy and mobility.
Therefore, only Course I logically follows from the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000093');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000093', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000093', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000093');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000094', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and determine which courses of action are appropriate and complementary. Statement: Child labor remains prevalent in certain industries and agricultural sectors, affecting children''s education, health, and development despite legal prohibitions. Courses of Action: I. Strengthen enforcement of child labor laws with regular inspections and severe penalties for violators. II. Provide educational scholarships and vocational training to vulnerable children to reduce economic incentives for child labor.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Both I and II follow', 'Course I is logical and necessary because stronger enforcement with inspections and penalties creates legal deterrence against child labor.
This is essential for stopping exploitation.
Course II is equally important because addressing the economic root cause—poverty—reduces families'' reliance on children''s income.
Educational scholarships and vocational training provide alternatives and long-term solutions.
Both actions are complementary—enforcement stops exploitation while development addresses its causes.
Therefore, both courses logically follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000094');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000094', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000094', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000094');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000095', 'dddddddd-dddd-dddd-dddd-00000000000a', 'Read the statement and evaluate which courses of action are practical and result-oriented. Statement: Healthcare accessibility is severely limited in remote areas due to lack of infrastructure, medical professionals, and transportation, while government budgets are constrained. Courses of Action: I. Deploy telemedicine services and train community health workers to provide basic healthcare in remote areas. II. Build state-of-the-art hospitals in every remote location regardless of cost and population size.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Cannot determine"]}', 'Only I follows', 'Course I is logical and feasible because telemedicine leverages existing technology to overcome distance barriers while training community health workers builds local capacity.
This solution is cost-effective and implementable with limited budgets.
Course II is impractical because building advanced hospitals everywhere is economically unrealistic and violates resource allocation efficiency.
Not every remote area can support large hospitals based on population and viability.
Therefore, only Course I logically follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000095');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000095', 'eeeeeeee-eeee-eeee-eeee-00000000000a', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000095', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000095');

-- Seating Arrangements -> topic Seating Arrangements
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000b', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Seating Arrangements', 'Determines seating positions or orders of people in linear or circular patterns based on clues', 'MEDIUM', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000b');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Seating Arrangements Challenge', 'Apply seating arrangements skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000096', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Eight people sit around a circular table facing center. A is second to the right of B. D is opposite A. E is to the immediate left of D. What is the position of B relative to E?', 'MCQ', 'MEDIUM', '{"options": ["Immediate right of E", "Second to the left of E", "Third to the left of E", "Immediate left of E", "Third to the right of E"]}', 'Third to the left of E', '8 people in circle (positions 1-8). Let B = position 1. A is second right of B: position 1 + 2 = position 3. D is opposite A: position 3 opposite to position 7. E is immediate left of D: position 6. Now, from E (position 6), B is Third to the left of E.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000096');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000096', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000096', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000096');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000097', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Nine individuals — A, B, C, D, E, F, G, H, and I — are seated in a straight line, all facing south, but not necessarily in the same order. D sits fourth to the right of B, and neither of them is at an end. Exactly one person sits between D and G, and G sits to the left of D. The number of persons to the right of D is one less than the number of persons to the left of F. Exactly two persons sit between F and E. The number of persons between E and D is equal to the number of persons between H and I. A sits second to the left of H. Who sits second to the left of C?', 'MCQ', 'HARD', '{"options": ["I", "The person third to the right of F", "The person immediately right of G", "E", "Both C and D"]}', 'The person third to the right of F', 'The correct left-to-right arrangement is:C – H – D – A – G – F – B – I – E.
Thus, the person third to the right of F sits second to the left of C.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000097');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000097', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000097', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000097');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000098', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Six people A, B, C, D, E, F sit around a circular table facing center. A sits opposite D. C is seated second to the left of E. A and F are immediate neighbours. B and E are immediate neighbours. Who is seated opposite B?', 'MCQ', 'MEDIUM', '{"options": ["A", "B", "C", "D", "Cannot be determined"]}', 'C', 'From the given information:

A is opposite D. A and F are neighbors. B and E are neighbors. C is second to the left of E.

Based on these conditions, a possible seating arrangement is A, B, E, D, C, F (in clockwise order).

Therefore, C is seated opposite B.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000098');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000098', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000098', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000098');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000099', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Nine individuals — A, B, C, D, E, F, G, H, and I — are seated in a straight line, all facing south, but not necessarily in the same order. D sits fourth to the right of B, and neither of them is at an end. Exactly one person sits between D and G, and G sits to the left of D. The number of persons to the right of D is one less than the number of persons to the left of F. Exactly two persons sit between F and E. The number of persons between E and D is equal to the number of persons between H and I. A sits second to the left of H.', 'MCQ', 'HARD', '{"options": ["Second to the right", "Second to the left", "Third to the left", "Immediate left", "None"]}', 'Third to the left', 'From the final arrangement:
C – H – D – A – G – F – B – I – E.
I is third to the left of G.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000099');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000099', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000099', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000099');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009a', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Six people A, B, C, D, E, F sit around a circular table facing center. A is opposite D. E and F are seated opposite each other. B is to the immediate right of A. Who is opposite B?', 'MCQ', 'EASY', '{"options": ["C", "E", "F", "D", "Cannot be determined"]}', 'C', 'Six people in circle (positions 1-6).A is opposite D.E and F are seated opposite each other.So, C is opposite B.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009a', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009a', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009b', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Six people sit around a circular table, all facing the center. A is to the right of F. D is opposite A. C is to the immediate left of B. Who is to the immediate right of A?', 'MCQ', 'MEDIUM', '{"options": ["B", "D", "C", "F", "Cannot be determined"]}', 'C', 'Based on the information, the possible clockwise arrangement is A, F, E, D, B, and C. Therefore, C is immediately to the right of A.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009b', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009b', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009c', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Eight people sit in two rows (A, B, C, D in Row 1 facing North and E, F, G, H in Row 2 facing South). A faces E. B faces F. C faces G. D faces H. B is to the right of A. G is to the left of H. Who sits to the immediate right of C?', 'MCQ', 'MEDIUM', '{"options": ["D", "H", "G", "E", "Cannot be determined"]}', 'D', 'Row 1 (facing North): A, B, C, D from left to right. B right of A (confirmed). Row 2 (facing South, so reverse): E, F, G, H. Since facing opposite directions, H, G, F, E when viewed from same perspective. G left of H in Row 2 means in absolute position. Matching pairs: A-E, B-F, C-G, D-H. Row 1 order: A, B, C, D. Person to immediate right of C is D.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009c', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009c', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009d', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Six people P, Q, R, S, T, U are sitting in a row. P is at the leftmost end. Q is immediate right of P. S is at the rightmost end. U is immediate left of S. R is between Q and T. What is the position of T from the left?', 'MCQ', 'EASY', '{"options": ["Second", "Third", "Fourth", "Fifth", "Cannot be determined"]}', 'Fourth', 'Positions: P is 1st (leftmost). Q is to the right of P. S is 6th (rightmost). U is immediate left of S. is R is between Q and T. Possible Arrangement : P, Q, R, T, U, S. So, T is fourth from left.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009d', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009d', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009e', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Nine people sit in a row. P is at one end. Q is at the other end. R is second to the right of P. S is second to the left of Q. T sits exactly in the middle of R and S, with one person between each pair. What is the position of T from left if P is on the left?', 'MCQ', 'MEDIUM', '{"options": ["4th", "5th", "6th", "7th", "Cannot be determined"]}', '5th', 'Placing P at position 1 and Q at position 9:

R is second to the right of P → R at position 3.
S is second to the left of Q → S at position 7.
T sits exactly between R and S with one person on each side → T must be at position 5.

Therefore, T is 5th from the left.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009e', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009e', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009f', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Five friends A, B, C, D, and E are sitting in a row facing North. A is at the start of the row, immediately followed by B. C is to the right of D. E is at the rightmost end. What is the position of C from the left?', 'MCQ', 'EASY', '{"options": ["First", "Second", "Third", "Fourth", "Cannot be determined"]}', 'Fourth', 'Given: B is immediately right of A. C is right of D. E is at extreme right (5th position). E is at position 5. Possible positions: A, B, D, C, E  from left.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009f', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000009f', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000009f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a0', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Twelve people are seated in two parallel rows facing each other. Row 1 (facing north): A, B, C, D, E, F Row 2 (facing south): P, Q, R, S, T, U E sits next to B, and B is not at an extreme end. E sits opposite the person who is second to the left of S. T sits opposite the person who is second to the left of D. D is neither opposite Q nor adjacent to E. The number of people between T and R equals the number between A and F. B sits four positions away from the person opposite Q. U sits to the left of P. R sits immediately to the left of T. F sits opposite S. C does not sit at an extreme end. Who sits opposite the person who is second to the left of P?', 'MCQ', 'HARD', '{"options": ["A", "B", "C", "D", "None"]}', 'B', 'Final arrangement:
Row 2: Q – S – P – T – R – U
Row 1: A – F – C – E – B – D
Hence, B sits opposite the required person.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a0', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a0', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a0');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a1', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Five people sitting in a row: M is to the immediate left of N. O is to the immediate right of N. P is to the left of M. Q is at the rightmost end. What is the correct arrangement from left to right?', 'MCQ', 'EASY', '{"options": ["P, M, N, O, Q", "M, P, N, O, Q", "P, O, M, N, Q", "M, N, O, P, Q", "Q, O, N, M, P"]}', 'P, M, N, O, Q', 'M is immediate left of N. O is immediate right of N. So: M-N-O (consecutive). P is left of M. Q is rightmost (5th position). Arrangement: P, M, N, O, Q. This satisfies all conditions: P left of M, M left of N, O right of N, Q rightmost.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a1', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a1', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a1');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a2', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. A group of people is seated in a straight line facing north. The total number does not exceed 22. Exactly eight persons sit between X and Z. Y sits third to the left of X. Five persons sit between Y and W. N sits exactly between U and M. V sits immediately to the left of W. Four persons sit between V and R. At most two persons sit between M and Z. The number of persons between R and X is the same as between X and T. Three persons sit between T and U. W does not sit exactly between Y and Z. M sits at one end of the row. What is the position of N with respect to X?', 'MCQ', 'HARD', '{"options": ["5th to the left", "4th position to the right", "3rd position to left", "6th position to the right", "None"]}', '6th position to the right', 'After placing all conditions correctly, N is found to be sixth to the right of X.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a2', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a2', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a2');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a3', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Four people A, B, C, D sit around a circular table facing the center. A is to the immediate right of B. C is opposite B. What is the position of D?', 'MCQ', 'EASY', '{"options": ["Immediate left of C", "Immediate right of A", "Opposite A", "Between A and C", "Cannot be determined"]}', 'Opposite A', 'Circular arrangement with 4 people facing center. B is fixed. A is immediate right of B (clockwise from B). C is opposite B. In a circle of 4: positions are B, A (right of B), next person, opposite B. C is opposite B. D must be the remaining position. D is opposite A (4th position). Answer: D is opposite A.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a3', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a3', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a3');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a4', 'dddddddd-dddd-dddd-dddd-00000000000b', 'Study the given information carefully and answer the question that follows. Twelve people sit around a circular table facing center. A is second to the right of B. D is opposite to A. G is second to the left of D. H is immediate right of G. E is second to the right of A. F is opposite E. What is the position of F relative to B?', 'MCQ', 'HARD', '{"options": ["Immediate right of B", "Second to the left of B", "Opposite B", "Third to the left of B", "Cannot be determined"]}', 'Second to the left of B', '12-person circle (positions 1-12). Let B = position 1. A is 2nd right of B = position 3. D opposite A = position 9. G is 2nd left of D = position 7. H immediate right of G = position 8. E is 2nd right of A = position 5. F opposite E = position 11. B is at 1, F is at 11. From B(1) to F(11): 10 positions right or 2 left. So, Second to left of B = position 11 (where F is).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a4', 'eeeeeeee-eeee-eeee-eeee-00000000000b', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a4', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a4');

-- Alphabet Series -> topic Alphabet Series
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000c', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Alphabet Series', 'Focuses on letter-based sequences analyzed to find missing or following letters', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000c');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Alphabet Series Challenge', 'Apply alphabet series skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a5', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next letter in the reverse alphabetical series: Z, Y, X, W, ?', 'MCQ', 'EASY', '{"options": ["U", "V", "T", "R", "S"]}', 'V', 'Letters move backward by –1 each step: Z→Y→X→W→V. Correct answer: V.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a5', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a5', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a6', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next pair following the alternating forward and backward letter patterns: A, Z, B, Y, C, X, ?', 'MCQ', 'EASY', '{"options": ["F, V", "D, W", "D, V", "E, V", "E, W"]}', 'D, W', 'Two alternating patterns: A–B–C–D (forward), Z–Y–X–W (backward). Next pair: D, W. Correct answer: D, W.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a6', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a6', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a7', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next letter in the skipping letter sequence (+3 pattern): B, E, H, K, ?', 'MCQ', 'MEDIUM', '{"options": ["M", "N", "Q", "O", "P"]}', 'N', 'Letter positions: 2, 5, 8, 11 (+3 each). Next = 14 = N. Correct answer: N.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a7', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a7', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a8', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next letter in the advanced alternating positional pattern: C, F, K, R, ?', 'MCQ', 'HARD', '{"options": ["A", "C", "Z", "AB", "Y"]}', 'A', 'Letters → positions: C(3), F(6), K(11), R(18). Differences: 6 − 3 = 3, 11 − 6 = 5, 18 − 11 = 7 (increments: +3, +5, +7). Next increment = 7 + 2 = 9. Next position = 18 + 9 = 27 → 27 − 26 = 1 → letter 1 = A. Next letter = A.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a8', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a8', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a9', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next letter in the reverse movement pattern: T, R, P, N, ?', 'MCQ', 'MEDIUM', '{"options": ["J", "L", "K", "M", "H"]}', 'L', 'Letters move backward by –2 each step: T→R→P→N→L. Correct answer: L.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a9', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000a9', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000a9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000aa', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next letter in the repeating and skipping pattern: A, A, C, C, F, F, J, J, ?', 'MCQ', 'HARD', '{"options": ["P", "M", "L", "N", "O"]}', 'O', 'Letter positions: +2, +3, +4, +5 pattern → after J(10)+5=O(15). Correct answer: O.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000aa');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000aa', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000aa', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000aa');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ab', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next letter following the cyclic alphabet pattern: X, A, D, G, J, ?', 'MCQ', 'HARD', '{"options": ["N", "M", "P", "O", "L"]}', 'M', 'Letter positions: X(24)→A(1)=+3 cyclically; +3 each step gives next = M(13). Correct answer: M.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ab');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ab', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ab', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ab');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ac', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next group of letters following the given pattern: AB, BC, CD, DE, ?', 'MCQ', 'MEDIUM', '{"options": ["EF", "GH", "DE", "DF", "FG"]}', 'EF', 'Each group moves one step forward: A→B→C→D→E and B→C→D→E→F. Next: EF. Correct answer: EF.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ac');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ac', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ac', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ac');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ad', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next pair following the alternating letter movement pattern: A, D, C, F, E, H, ?', 'MCQ', 'MEDIUM', '{"options": ["G, J", "G, K", "H, J", "G, I", "F, I"]}', 'G, J', 'Odd positions: A, C, E, G (+2); Even: D, F, H, J (+2). Next pair: G, J. Correct answer: G, J.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ad');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ad', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ad', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ad');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ae', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next letter in the continuous sequence of alphabets: A, B, C, D, ?', 'MCQ', 'EASY', '{"options": ["H", "F", "I", "G", "E"]}', 'E', 'Letters move forward by +1 each step: A→B→C→D→E. Correct answer: E.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ae');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ae', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ae', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ae');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000af', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next letter based on increasing positional differences: A, D, H, M, S, ?', 'MCQ', 'MEDIUM', '{"options": ["AA", "AB", "X", "Y", "Z"]}', 'Z', 'Differences: +3, +4, +5, +6, +7. So next: S(19)+7=26→Z. Correct answer: Z.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000af');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000af', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000af', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000af');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b0', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next letter in the series by skipping one letter each time: A, C, E, G, ?', 'MCQ', 'EASY', '{"options": ["K", "I", "J", "H", "L"]}', 'I', 'Letters skip one each time (+2): A(1), C(3), E(5), G(7) → I(9). Correct answer: I.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b0', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b0', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b0');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b1', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Find the next pair of letters in the complex alternating pattern: A, E, D, H, G, K, ?', 'MCQ', 'HARD', '{"options": ["I, N", "L, O", "J, N", "K, N", "J, M"]}', 'J, N', 'Odd letters: A, D, G, J (+3); Even letters: E, H, K, N (+3). Next: J, N. Correct answer: J, N.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b1', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b1', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b1');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b2', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next pair in the alternating forward-backward pattern: A, Z, C, X, E, V, ?', 'MCQ', 'HARD', '{"options": ["G, U", "H, T", "G, T", "F, T", "H, U"]}', 'G, T', 'Odd: A, C, E, G (+2); Even: Z, X, V, T (–2). Next pair: G, T. Correct answer: G, T.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b2', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b2', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b2');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b3', 'dddddddd-dddd-dddd-dddd-00000000000c', 'Identify the next letter following the repetition pattern: A, A, B, B, C, C, ?', 'MCQ', 'EASY', '{"options": ["C", "F", "E", "G", "D"]}', 'D', 'Each letter repeats twice: A, A, B, B, C, C → D, D next. Correct answer: D.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b3', 'eeeeeeee-eeee-eeee-eeee-00000000000c', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b3', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b3');

-- Analogy -> topic Analogy
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000d', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Analogy', 'Tests relationships between pairs of words, numbers, or figures to find similar relationships', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000d');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Analogy Challenge', 'Apply analogy skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b4', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Find the pair showing similar degree of relationship: Warm : Hot :: Cool : ?', 'MCQ', 'MEDIUM', '{"options": ["Chilly", "Cold", "Temperate", "Freezing", "Mild"]}', 'Cold', 'Explanation: Relationship = Degree or intensity. Warm → Hot shows increase in heat. Cool → Cold shows decrease in temperature. Step 1: Recognize intensity pattern. Step 2: Apply similar relationship. Correct answer: Cold.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b4', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b4', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b4');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b5', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Find the pair showing the same opposite relationship: Generous : Stingy :: Brave : ?', 'MCQ', 'HARD', '{"options": ["Bold", "Heroic", "Timid", "Fearless", "Cowardly"]}', 'Cowardly', 'Explanation: Relationship = Antonyms. Generous ↔ Stingy are opposites. Brave ↔ Cowardly are opposites. Step 1: Identify relationship type (Antonym). Step 2: Apply same logic to second pair. Correct answer: Cowardly.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b5', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b5', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b6', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the number relationship and find the missing term: 2 : 8 :: 3 : ?', 'MCQ', 'MEDIUM', '{"options": ["6", "18", "9", "12", "27"]}', '27', 'Explanation: Relationship = n → n³. 2³ = 8. 3³ = 27. Step 1: Identify cube pattern in first pair. Step 2: Apply same to 3. Correct answer: 27.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b6', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b6', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b7', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Determine the mathematical relationship: 4 : 11 :: 7 : ?', 'MCQ', 'HARD', '{"options": ["23", "20", "19", "22", "26"]}', '20', 'Explanation: Operation: (×3) − 1. 4×3 − 1 = 11. 7×3 − 1 = 20. Step 1: Identify arithmetic pattern. Step 2: Apply to second number. Correct answer: 20.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b7', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b7', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b8', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the sequential relationship: Infant : Child :: Child : ?', 'MCQ', 'MEDIUM', '{"options": ["Toddler", "Elder", "Teenager", "Baby", "Adult"]}', 'Adult', 'Explanation: Relationship = Growth sequence. Infant grows into a child. Child grows into an adult. Step 1: Observe life-stage order. Step 2: Apply same next step. Correct answer: Adult.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b8', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b8', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b9', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the user of the given tool: Stethoscope : Doctor :: Microscope : ?', 'MCQ', 'MEDIUM', '{"options": ["Scientist", "Carpenter", "Teacher", "Nurse", "Student"]}', 'Scientist', 'Explanation: Relationship = Tool : User. Stethoscope is used by a doctor. Microscope is used by a scientist. Step 1: Recognize the professional using the tool. Step 2: Apply the same logic. Correct answer: Scientist.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b9', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000b9', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000b9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ba', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the function of the given object and choose the correct analogy: Pen : Write :: Knife : ?', 'MCQ', 'EASY', '{"options": ["Measure", "Stir", "Tie", "Cut", "Paint"]}', 'Cut', 'Explanation: Relationship = Tool : Primary function. A pen is used to write. A knife is used to cut. Step 1: Identify the object (Knife). Step 2: Determine its main action (Cut). Correct answer: Cut.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ba');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ba', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ba', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ba');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bb', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the object-function relationship: Book : Reading :: Clock : ?', 'MCQ', 'MEDIUM', '{"options": ["Watch", "Time", "Hours", "Ticking", "Alarm"]}', 'Time', 'Explanation: Relationship = Object : Primary purpose. A book is used for reading. A clock is associated with time. Step 1: Identify main concept for each item. Step 2: Apply same to clock. Correct answer: Time.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bb');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bb', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bb', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bb');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bc', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the relationship between the given pair of words and find the corresponding term: Teacher : School :: Doctor : ?', 'MCQ', 'EASY', '{"options": ["Hospital", "Clinic", "Laboratory", "Office", "Pharmacy"]}', 'Hospital', 'Explanation: Relationship = Profession : Workplace. A doctor usually works in a hospital. Step 1: Identify the first pair relationship (Teacher : School). Step 2: Apply same relation to the second (Doctor : ?). Step 3: Doctor → Hospital. Correct answer: Hospital.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bc');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bc', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bc', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bc');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bd', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Observe the letter relationship and find the corresponding letter: A : C :: M : ?', 'MCQ', 'EASY', '{"options": ["O", "N", "P", "Q", "L"]}', 'O', 'Explanation: Letter positions: A(1) → C(3) = +2. Apply same to M(13): 13 + 2 = 15 → O. Step 1: Identify alphabet position pattern. Step 2: Add +2 to the position of M. Step 3: 13 + 2 = 15 → O. Correct answer: O.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bd');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bd', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bd', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bd');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000be', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Determine the cause–effect relationship: Smoke : Fire :: Fever : ?', 'MCQ', 'HARD', '{"options": ["Sweat", "Cough", "Cold", "Headache", "Infection"]}', 'Infection', 'Explanation: Relationship = Effect : Cause. Smoke is caused by fire. Fever is caused by infection. Step 1: Recognize causal relation. Step 2: Identify cause in second pair. Correct answer: Infection.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000be');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000be', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000be', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000be');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bf', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the part-whole relationship and complete the analogy: Wheel : Car :: Finger : ?', 'MCQ', 'EASY', '{"options": ["Arm", "Hand", "Nail", "Toe", "Leg"]}', 'Hand', 'Explanation: Relationship = Part : Whole. A wheel is part of a car. A finger is part of a hand. Step 1: Recognize the part-whole connection. Step 2: Apply same pattern to second pair. Correct answer: Hand.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bf');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bf', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000bf', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000bf');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c0', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Identify the purpose relationship of the given tools: Brush : Paint :: Pen : ?', 'MCQ', 'HARD', '{"options": ["Ink", "Write", "Sketch", "Paper", "Draw"]}', 'Write', 'Explanation: Relationship = Tool : Purpose. A brush is used for painting. A pen is used for writing. Step 1: Identify action associated with tool. Step 2: Apply same logic. Correct answer: Write.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c0', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c0', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c0');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c1', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Find the word related in the same way as the first pair: Big : Large :: Small : ?', 'MCQ', 'EASY', '{"options": ["Huge", "Little", "Short", "Large", "Tiny"]}', 'Tiny', 'Explanation: Relationship = Synonym. Big ≈ Large. Small ≈ Tiny. Step 1: Identify type of relationship (Synonym). Step 2: Find similar meaning for Small → Tiny. Correct answer: Tiny.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c1', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c1', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c1');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c2', 'dddddddd-dddd-dddd-dddd-00000000000d', 'Find the numerical pattern based on letter positions: B : 4 :: E : ?', 'MCQ', 'HARD', '{"options": ["10", "8", "12", "7", "6"]}', '10', 'Explanation: B = 2 → 2×2 = 4. E = 5 → 5×2 = 10. Step 1: Identify arithmetic rule (×2). Step 2: Apply to E’s position (5×2=10). Correct answer: 10.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c2', 'eeeeeeee-eeee-eeee-eeee-00000000000d', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c2', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c2');

-- Coding–Decoding -> topic Coding–Decoding
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000e', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Coding–Decoding', 'Covers logic-based encoding and decoding of words, letters, or numbers using specific rules', 'MEDIUM', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000e');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Coding–Decoding Challenge', 'Apply coding–decoding skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c3', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Replace symbols with given operations and evaluate: If 6 @ 3 \$ 2 = 20 and @ means ×, \$ means +, find 5 @ 4 \$ 3.', 'MCQ', 'MEDIUM', '{"options": ["26", "23", "19", "22", "20"]}', '23', 'Substituting the operators changes the expression to \(5 \times 4 + 3\), which evaluates to 23 by performing multiplication before addition.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c3', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c3', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c3');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c4', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Use code-word mapping to identify the code for the target word: If ‘pa la na’ = ‘sky is blue’, ‘la ma ta’ = ‘blue and green’, and ‘ma sa pa’ = ‘and sky clear’, then what is the code for ‘green’?', 'MCQ', 'MEDIUM', '{"options": ["na", "ma", "ta", "pa", "la"]}', 'ta', 'Explanation: 1. From pa la na = sky is blue and la ma ta = blue and green, the common word is blue, so la = blue. 2. In la ma ta = blue and green, since la = blue, the remaining codes ma and ta map to and and green. 3. ma appears in ma sa pa = and sky clear, so ma = and (matches that sentence). 4. Therefore ta = green.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c4', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c4', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c4');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c5', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Trace the chain of substitutions to find the original mapping: If ‘Sun’ is coded as ‘Moon’, and ‘Moon’ is coded as ‘Star’, then what will be the code for ‘Sun’?', 'MCQ', 'MEDIUM', '{"options": ["Sky", "Earth", "Light", "Star", "Moon"]}', 'Star', 'Explanation: Chain substitution – Sun→Moon→Star. Hence, the word coded as Sun = Star. Step-by-step: Track word substitution sequence.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c5', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c5', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c6', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the numeric code by substituting letter positions: If A=1, B=2, C=3, then what is the code for ACE?', 'MCQ', 'EASY', '{"options": ["315", "135", "351", "153", "513"]}', '135', 'Explanation: Substitute alphabet positions → A=1, C=3, E=5 → Code = 135. Step-by-step: Replace each letter with numeric position.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c6', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c6', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c7', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the coded form using the given letter-shift rule: If CAT = DBU, then DOG = ?', 'MCQ', 'EASY', '{"options": ["DPH", "EOF", "EPH", "ENF", "FPI"]}', 'EPH', 'Explanation: Rule – Each letter is shifted by +1. C→D, A→B, T→U; so D→E, O→P, G→H → Answer: EPH. Step-by-step: Identify +1 shift → Apply same to target word → DOG → EPH.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c7', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c7', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c8', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Substitute symbols with operations and evaluate the expression: If 9 # 3 @ 2 = 6, where # means ÷ and @ means ×, then find value of 8 @ 2 # 4.', 'MCQ', 'HARD', '{"options": ["12", "10", "16", "20", "4"]}', '4', 'Explanation: Rule: Replace $\#$ with $\div$ and $@$ with $\times$. (Note: The premise $9 \text{ # } 3 \text{ @ } 2 = 27$ is incorrect, as $9 \div 3 \times 2 = 6$. We apply the given rules regardless.) Step 1: $8 \text{ @ } 2 \text{ # } 4$ becomes $8 \times 2 \div 4$. Step 2: Evaluate: $16 \div 4 = 4$. Correct answer: 4.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c8', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c8', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c9', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the coded form using the given letter-shift rule: If TRAIN = USBJO, find the code for PLACE.', 'MCQ', 'EASY', '{"options": ["QMBDF", "RMBDF", "QMADE", "PMBDF", "QNBDF"]}', 'QMBDF', 'Explanation: Each letter shifted +1 → P→Q, L→M, A→B, C→D, E→F → QMBDF. Step-by-step: Apply +1 shift to each letter.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c9', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000c9', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000c9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ca', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Apply opposite-letter mapping to find the coded word: If HELP = SVOK, then CARE = ?', 'MCQ', 'HARD', '{"options": ["XZRU", "XZRI", "XZIV", "XZIW", "XZIR"]}', 'XZIV', 'Rule: Replace each letter by its opposite pair ($A \leftrightarrow Z$, $B \leftrightarrow Y$, etc.). (Note: The premise $HELP = SVOK$ has a typo. The opposite of $P$ is $K$, so the code should be $SVOK$. We apply the $opposite$ rule regardless.) Step 1 (Premise): $H \leftrightarrow S$, $E \leftrightarrow V$, $L \leftrightarrow O$. Step 2 (Target): Apply the same rule to CARE: $C \leftrightarrow X$, $A \leftrightarrow Z$, $R \leftrightarrow I$, $E \leftrightarrow V$. Correct answer: XZIV.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ca');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ca', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ca', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ca');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cb', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Determine the coding rule based on letter positions concatenation: If RAM = 18113 and PAN = 16114, find rule.', 'MCQ', 'HARD', '{"options": ["Concatenate letter positions", "Each letter position added", "Reverse order positions", "Subtract consecutive letters", "Multiply letter positions"]}', 'Concatenate letter positions', 'Explanation: R(18), A(1), M(13) → Combine → 18113. Same pattern holds for PAN (P16, A1, N14). Step-by-step: Replace each letter with position and join.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cb');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cb', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cb', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cb');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cc', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Determine the coding rule from the example and state it: If $SKY = 191125$, what is the rule?', 'MCQ', 'MEDIUM', '{"options": ["Reverse order", "Concatenate positions", "Multiply positions", "Sum of letters", "Add position numbers"]}', 'Concatenate positions', 'Explanation: S(19), K(11), Y(25) → Combine → 191125. Step-by-step: Write alphabet numbers, then join together.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cc');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cc', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cc', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cc');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cd', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the reversed form of the given word: If BALL = LLAB, then CAT = ?', 'MCQ', 'EASY', '{"options": ["ACT", "TAC", "ATC", "CTA", "TCA"]}', 'TAC', 'Explanation: Rule – Word is reversed. BALL → LLAB; CAT → TAC. Step-by-step: Reverse the letters.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cd');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cd', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cd', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cd');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ce', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the coded form using the +1 shift rule: If MANGO = NBOHP, find the code for GRAPE.', 'MCQ', 'MEDIUM', '{"options": ["HSBQE", "HSBQF", "HSCQF", "HSCPF", "HTBPF"]}', 'HSBQF', 'Explanation: Rule – Each letter shifted by +1. G→H, R→S, A→B, P→Q, E→F → HSBQF. Step-by-step: Apply +1 shift to each letter.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ce');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ce', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ce', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ce');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cf', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Follow reverse and shift operations to find the coded output: If CAT = TBU, then DOG = ?', 'MCQ', 'HARD', '{"options": ["HPI", "HPH", "GPI", "GPH", "EPH"]}', 'GPH', 'The coding rule is complex: 1. Code_Letter1 = Original_Letter3 ($C \underline{A} \underline{\underline{T}} \rightarrow \underline{\underline{T}}BU$) 2. Code_Letter2 = Original_Letter2 $+ 1$ ($C \underline{A} T \rightarrow T \underline{B} U$) 3. Code_Letter3 = Original_Letter3 $+ 1$ ($C A \underline{\underline{T}} \rightarrow TB \underline{\underline{U}}$) Step 1 (CAT): $C(1)A(2)T(3) \rightarrow T$ (Letter 3) + $B$ (A+1) + $U$ (T+1) = $TBU$. (Matches premise) Step 2 (DOG): $D(1)O(2)G(3) \rightarrow G$ (Letter 3) + $P$ (O+1) + $H$ (G+1) = $GPH$. Correct answer: GPH.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cf');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cf', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000cf', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000cf');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d0', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Find the coded word using opposite-letter mapping (A↔Z): If DOG = WLT, then CAT = ?', 'MCQ', 'EASY', '{"options": ["XZG", "XZH", "XYG", "XZA", "YZG"]}', 'XZG', 'Explanation: Rule – Replace each letter by its opposite (A↔Z, B↔Y,…). D(4)↔W(23), O↔L, G↔T → C↔X, A↔Z, T↔G → CAT = XZG. Step-by-step: Use opposite letter rule.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d0', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d0', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d0');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d1', 'dddddddd-dddd-dddd-dddd-00000000000e', 'Square each letter’s alphabetical position and combine to form the code: If A=1, B=2,… Z=26, find code for ‘ABCD’ if each letter’s position is squared.', 'MCQ', 'HARD', '{"options": ["14169", "14916", "14925", "14164", "149"]}', '14916', 'Rule: Replace each letter with the square of its alphabetical position ($n^2$) and concatenate the result Step 1: $A(1) \rightarrow 1^2 = 1$. Step 2: $B(2) \rightarrow 2^2 = 4$. Step 3: $C(3) \rightarrow 3^2 = 9$. Step 4: $D(4) \rightarrow 4^2 = 16$. Step 5: Concatenate: $1$ & $4$ & $9$ & $16 \rightarrow 14916$. Correct answer: 14916.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d1', 'eeeeeeee-eeee-eeee-eeee-00000000000e', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d1', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d1');

-- Directions / Direction Sense -> topic Directions / Direction Sense
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-00000000000f', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Directions / Direction Sense', 'Solves problems related to movement, turns, and directions in reference to starting points', 'MEDIUM', 21, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-00000000000f');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'dddddddd-dddd-dddd-dddd-00000000000f', 'Directions / Direction Sense Challenge', 'Apply directions / direction sense skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-00000000000f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d2', 'dddddddd-dddd-dddd-dddd-00000000000f', 'If at 3 PM a man''s shadow is exactly in front of him, which direction is he facing? (Assume standard sun path)', 'MCQ', 'MEDIUM', '{"options": ["East", "West", "North", "South", "Cannot be determined"]}', 'East', 'At 3 PM, the sun is in the West, so the shadow falls towards the East. If the shadow is exactly in front of him, he is facing East.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d2', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d2', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d2');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d3', 'dddddddd-dddd-dddd-dddd-00000000000f', 'At sunrise a man''s shadow falls exactly to his left. Which direction is he facing?', 'MCQ', 'EASY', '{"options": ["North-East", "North", "East", "South", "West"]}', 'North', 'At sunrise, the sun is in the East, so the shadow falls towards the West. If the shadow is to the man''s left, then West is on his left side. Therefore, he is facing North.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d3', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d3', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d3');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d4', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A starts from point O and walks 6 km north, turns right and walks 5 km, turns right and walks 6 km, turns left and walks 10 km. How far and in which direction is he from O?', 'MCQ', 'HARD', '{"options": ["10 km East", "5 km East", "5 km West", "10 km West", "15 km East"]}', '15 km East', 'A walks: 6 km North. 5 km East. 6 km South. 10 km East. North and South cancel out. Total East distance = 5 + 10 = 15 km. A is 15 km East from O.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d4', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d4', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d4');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d5', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A person walks 10 m south, turns left, walks 6 m, turns left, walks 10 m. Where is he relative to starting point?', 'MCQ', 'EASY', '{"options": ["10 m north", "6 m east", "6 m west", "10 m south", "At starting point"]}', '6 m east', 'Walks 10 m south. Turns left → walks 6 m east. Turns left again → walks 10 m north. He ends up 6 m east of the starting point.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d5', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d5', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d6', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A person faces East. He makes two successive left turns. Which direction is he facing now?', 'MCQ', 'EASY', '{"options": ["East", "North", "North-East", "South", "West"]}', 'West', 'A person initially faces East. First left turn: North. Second left turn: West. So, he is now facing West.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d6', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d6', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d7', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A walks 3 km east, then 4 km north. How far (shortest) is he from the starting point?', 'MCQ', 'EASY', '{"options": ["1 km", "25 km", "5 km", "4 km", "7 km"]}', '5 km', 'A walks 3 km east and 4 km north, forming a right triangle.

Shortest distance = √(3² + 4²) = √25 = 5 km.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d7', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d7', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d8', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A man faces South. He turns 3 rights, 2 lefts, 1 right and 1 left (in this order). Which direction is he facing finally?', 'MCQ', 'HARD', '{"options": ["North", "South", "East", "West", "Cannot be determined"]}', 'West', 'Start facing South. 3 rights: South → West → North → East. 2 lefts: East → North → West. 1 right: West → North. 1 left: North → West.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d8', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d8', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d9', 'dddddddd-dddd-dddd-dddd-00000000000f', 'P walks 12 km west, 5 km north, 12 km east, then 7 km south. How far and in which direction from starting point is P?', 'MCQ', 'HARD', '{"options": ["2 km South-West", "2 km South-East", "2 km North-East", "2 km South", "2 km North"]}', '2 km South', '12 km West and 12 km East cancel each other. Then: 5 km North. 7 km South. Net movement = 7 − 5 = 2 km South. P is 2 km South from the starting point.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d9', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000d9', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000d9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000da', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A man walks 5 km north, then turns right and walks 3 km. In which direction is he from the starting point?', 'MCQ', 'EASY', '{"options": ["South-West", "East", "North-West", "South-East", "North-East"]}', 'North-East', 'The man first walks 5 km north, then turns right, which means he walks 3 km east. So, from the starting point, he is located in the North-East direction.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000da');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000da', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000da', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000da');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000db', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A man walks 7 km north, 4 km east, 5 km south and 4 km west. How far is he from start?', 'MCQ', 'MEDIUM', '{"options": ["3 km", "5 km", "2 km", "4 km", "1 km"]}', '2 km', 'Step 1: North–south: 7−5=2 north. Step 2: East–west: 4−4=0. Step 3: Displacement = 2 km north. Correct answer: 2 km.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000db');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000db', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000db', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000db');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dc', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A man walks 5 km north, then 5 km east, then 7 km south-west (i.e., 7 km at 45° to south and west). Where is he relative to start?', 'MCQ', 'HARD', '{"options": ["2√2 km East and 2√2 km South", "2 km East and 2 km South", "√2 km West and √2 km South", "(5√2 - 7) km North-East", "Cannot be determined"]}', '(5√2 - 7) km North-East', 'Walking 5 km North and 5 km East places him 5√2 km directly North-East. Walking 7 km South-West moves him back along the same line. Since 5√2 is approximately 7.07 km, he stops (5√2 - 7) km short of the start, remaining North-East.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dc');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000dc', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dc', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000dc');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dd', 'dddddddd-dddd-dddd-dddd-00000000000f', 'Start facing East. Turn right, walk 4 km. Turn right, walk 3 km. Turn left, walk 2 km. Which direction are you facing at end?', 'MCQ', 'MEDIUM', '{"options": ["North", "West", "South-East", "South", "East"]}', 'South', 'Start facing East. Turn right → South. Turn right again → West. Turn left → South. So, the final direction is South.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dd');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000dd', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000dd', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000dd');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000de', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A man starts facing North. He walks 2 km, turns right and walks 3 km, turns right and walks 2 km, turns left and walks 4 km. Which direction is he facing at the end and how far from start?', 'MCQ', 'HARD', '{"options": ["Facing East, 7 km East", "Facing East, 3 km East", "Facing South, 3 km East", "Facing West, 1 km East", "Facing North, 7 km North"]}', 'Facing East, 7 km East', 'Sun’s Position: At sunrise, the sun is in the East. Shadow’s Direction: A shadow is always cast in the opposite direction of the light source. Therefore, the man’s shadow is pointing West. Facing Direction: If the man’s shadow (West) is on his left side, he must be facing North.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000de');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000de', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000de', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000de');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000df', 'dddddddd-dddd-dddd-dddd-00000000000f', 'Starting at P, Q walks 8 km west, then 3 km north, then 5 km east, then 2 km north. How far and in which direction is Q from P?', 'MCQ', 'MEDIUM', '{"options": ["√(25) km North-West", "5 km North-West", "√(13) km North-East", "√(34) km North-West", "√(13) km North-West"]}', '√(34) km North-West', 'West = 8 km, East = 5 km → Net 3 km west. North = 3 km + 2 km = 5 km north. So, Q is 3 km west and 5 km north of P, which is in the North-West direction. Shortest distance = √(3² + 5²) = √34 km.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000df');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000df', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000df', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000df');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e0', 'dddddddd-dddd-dddd-dddd-00000000000f', 'A person facing North turns 135° clockwise. Which direction is he facing?', 'MCQ', 'MEDIUM', '{"options": ["South-West", "North-West", "West", "South-East", "North-East"]}', 'South-East', 'Starting from North: 90° clockwise → East. Another 45° clockwise → South-East. So, he is facing South-East.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e0', 'eeeeeeee-eeee-eeee-eeee-00000000000f', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e0', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e0');

-- Syllogisms -> topic Syllogisms
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000010', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Syllogisms', 'Tests logical reasoning through statements and conclusions to determine valid inferences', 'MEDIUM', 22, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000010');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000010', 'dddddddd-dddd-dddd-dddd-000000000010', 'Syllogisms Challenge', 'Apply syllogisms skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000010');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e1', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All doctors are educated. Some educated people are rich. Conclusions: I. Some doctors are rich. II. All doctors are rich.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Only I may follow"]}', 'Only I may follow', 'All doctors are educated.
Some educated people are rich.
From ''Some educated are rich'', we cannot definitively say which ones are rich or if doctors are among them.
Conclusion I may follow (possible but not definite).
Conclusion II does not follow.
Only I may follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e1', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e1', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e1');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e2', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: Some artists are not painters. All painters are creative. Some creative people are not artists. Conclusions: I. Some artists are not creative. II. All creative people are painters.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II does not follow"]}', 'Neither I nor II follows', 'Some artists are not painters (A⊝B).
 All painters are creative (B→C).
 We cannot conclude whether some artists are not creative because some artists might be creative through other means.
 Conclusion I does not follow.
 From ''Some creative are not artists'', we cannot conclude all creative are painters.
 Conclusion II does not follow.
 Neither I nor II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e2', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e2', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e2');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e3', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All students are intelligent. All intelligent people are successful. Conclusions: I. All students are successful. II. Some students are successful.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Only I or II may follow"]}', 'Both I and II follow', 'All students are intelligent (A→B).
 All intelligent people are successful (B→C).
 By transitivity: All students are successful (A→C).
 Conclusion I follows.
 Since ''All A are C'' implies ''Some A are C'', Conclusion II also follows.
 Both I and II follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e3', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e3', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e3');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e4', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All doctors are professionals. No amateur is professional. Some people are amateurs. All professionals are experts. Conclusions: I. No doctor is an amateur. II. All amateurs are not experts. III. Some people are not doctors.', 'MCQ', 'HARD', '{"options": ["I, II follow", "I, III follow", "II, III follow", "All three follow", "Only I follows"]}', 'All three follow', 'All doctors are professionals (A→B).
 No amateur is professional (C×B).
 Therefore, no doctor is amateur (A×C).
 Conclusion I follows.
 From ''No amateur is professional'' and ''All professionals are experts'', no amateur is expert.
 Conclusion II follows.
 From ''Some people are amateurs'' and ''No doctor is amateur'', some people are not doctors.
 Conclusion III follows.
 All three follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e4', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e4', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e4');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e5', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: No pen is pencil. All pencils are stationery. Conclusions: I. No pen is stationery. II. Some stationery are not pens.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II follows"]}', 'Only II follows', 'No pen is pencil (A×B).
 All pencils are stationery (B→C).
 From these statements, we cannot conclude no pen is stationery because pens can be stationery through other means.
 However, from ''No pen is pencil'' and ''All pencils are stationery'', we can infer some stationery are not pens.
 Only II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e5', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e5', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e6', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All engineers are technical. Some technical people are not managers. All managers are decision-makers. Conclusions: I. Some engineers are not managers. II. No engineer is a manager. III. Some decision-makers are not engineers.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Only III follows", "I and III follow", "All three follow"]}', 'Only I follows', 'All engineers are technical (A→B).
 Some technical people are not managers (B⊝C).
 From ''All A are B'' and ''Some B are not C'', we can conclude some A are not C.
 Therefore, some engineers are not managers.
 Conclusion I follows.
 Conclusion II overgeneralizes (not all engineers are excluded from being managers).
 Conclusion III cannot be confirmed.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e6', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e6', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e7', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All trees are plants. No plant is an animal. Some living things are animals. Conclusions: I. No tree is an animal. II. Some living things are not trees.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Both I and II follow', 'All trees are plants (A→B).
 No plant is an animal (B×C).
 Therefore, no tree is an animal (A×C).
 Conclusion I follows.
 From ''Some living things are animals'' and ''No tree is an animal'', we can infer some living things are not trees.
 Conclusion II follows.
 Both I and II follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e7', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e7', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e8', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: Some leaders are politicians. All politicians are public servants. No corrupt person is a public servant. All leaders are honest. Conclusions: I. No politician is corrupt. II. Some leaders are public servants. III. No leader is corrupt.', 'MCQ', 'HARD', '{"options": ["Only I follows", "I and II follow", "I and III follow", "All three follow", "II and III follow"]}', 'All three follow', 'All politicians are public servants (A→B).
 No corrupt person is public servant (C×B).
 From these, no politician is corrupt (A×C).
 Conclusion I follows.
 Some leaders are politicians (D⊕A).
 All politicians are public servants (A→B).
 Therefore, some leaders are public servants (D⊕B).
 Conclusion II follows.
 All leaders are honest (D→E).
 No corrupt is public servant (C×B).
 All politicians are public servants means no politician is corrupt, and since some leaders are politicians, and leaders are honest (not corrupt), combined with transitive logic, no leader is corrupt.
 Conclusion III follows.
 All three follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e8', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e8', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e9', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: Some fruits are sweet. All sweet things are healthy. Some fruits are not healthy. Conclusions: I. Some fruits are healthy. II. Some fruits are not sweet.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Both I and II follow', 'Some fruits are sweet (A⊕B).
 All sweet things are healthy (B→C).
 From these, some fruits are healthy (A⊕C), so I follows.
 Given ''Some fruits are not healthy'' and ''All sweet are healthy'', it logically follows that these non-healthy fruits must not be sweet.
 Conclusion II follows.
 Both I and II follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e9', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000e9', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000e9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ea', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All books are knowledge sources. All knowledge sources are information providers. No misinformation provider is a knowledge source. Some information providers are misinformation providers. Conclusions: I. No book is a misinformation provider. II. Some misinformation providers are not books. III. All books are information providers.', 'MCQ', 'HARD', '{"options": ["I and II follow", "I and III follow", "II and III follow", "All three follow", "Only III follows"]}', 'All three follow', 'All books are knowledge sources (A→B).
 All knowledge sources are information providers (B→C).
 By transitivity: All books are information providers (A→C).
 Conclusion III follows.
 No misinformation provider is knowledge source (D×B).
 Combined with all books are knowledge sources, no book is misinformation provider (A×D).
 Conclusion I follows.
 From ''Some information providers are misinformation providers'' and ''No book is misinformation provider'', some information providers are not books.
 Conclusion II follows.
 All three follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ea');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ea', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ea', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ea');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000eb', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: No diamond is stone. All stones are minerals. Some minerals are valuable. Conclusions: I. Some valuable things are not diamonds. II. No diamond is mineral.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II follows"]}', 'Only I follows', 'No diamond is stone (A×B).
 All stones are minerals (B→C).
 From these, no diamond is mineral (A×C).
 Conclusion II follows.
 For Conclusion I: From ''Some minerals are valuable'' alone, we cannot definitively say some valuable things are not diamonds without more information.
 Only II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000eb');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000eb', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000eb', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000eb');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ec', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: Some novels are interesting. All interesting books are bestsellers. Conclusions: I. Some novels are bestsellers. II. Some novels are not bestsellers.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "I follows, II may follow", "Both I and II follow", "Neither follows"]}', 'Only I follows', 'Some novels are interesting (A⊕B).
 All interesting books are bestsellers (B→C).
 From these, some novels are bestsellers (A⊕C).
 Conclusion I follows.
 Conclusion II does not follow because we cannot determine which novels are not bestsellers.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ec');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ec', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ec', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ec');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ed', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All cats are animals. No animal is a stone. Conclusions: I. No cat is a stone. II. No stone is a cat.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I and II both may follow"]}', 'Both I and II follow', 'All cats are animals (A→B).
 No animal is a stone (B×C).
 Therefore, no cat is a stone (A×C).
 Conclusion I follows.
 By conversion rule, ''No cat is a stone'' converts to ''No stone is a cat'' (Conclusion II).
 Both I and II follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ed');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ed', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ed', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ed');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ee', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All teachers are knowledgeable. No fool is knowledgeable. Some people are fools. Conclusions: I. No teacher is a fool. II. Some people are not teachers.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I and II both may follow"]}', 'Both I and II follow', 'All teachers are knowledgeable (A→B).
 No fool is knowledgeable (C×B).
 From these, no teacher is a fool (A×C).
 Conclusion I follows.
 From ''Some people are fools'' and ''No teacher is a fool'', it logically follows that some people are not teachers.
 Conclusion II follows.
 Both I and II follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ee');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ee', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ee', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ee');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ef', 'dddddddd-dddd-dddd-dddd-000000000010', 'Directions: In the following question, some statements are followed by certain conclusions. Consider the given statements to be true even if they seem to be at variance with commonly known facts. Decide which of the conclusions logically follow(s) from the given statements. Statements: All flowers are plants. All plants are living things. Conclusions: I. All flowers are living things. II. All living things are flowers.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I and II both may follow"]}', 'Only I follows', 'Using transitive property: All flowers are plants, and all plants are living things → All flowers are living things.
Conclusion I is definite.
Conclusion II does not follow (not all living things are flowers, e.g., animals).
Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ef');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ef', 'eeeeeeee-eeee-eeee-eeee-000000000010', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ef', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ef');

-- Statement and Conclusions -> topic Statement and Conclusions
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000011', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Statement and Conclusions', 'Tests reasoning by analyzing which conclusions logically follow statements', 'MEDIUM', 23, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000011');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000011', 'dddddddd-dddd-dddd-dddd-000000000011', 'Statement and Conclusions Challenge', 'Apply statement and conclusions skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000011');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f0', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''Only qualified candidates can apply for this job.'' Conclusions: I. All unqualified candidates cannot apply. II. Some qualified candidates will apply.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Only I follows', 'From ''Only qualified candidates can apply'', Conclusion I logically follows (unqualified are excluded).
 Conclusion II assumes that qualified candidates will definitely apply, which is not stated.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f0');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f0', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f0', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f0');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f1', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statements: (1) All engineers are problem-solvers. (2) Some problem-solvers are creative. Conclusions: I. Some engineers are creative. II. All creative people are problem-solvers.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II doesn''t follow"]}', 'I may follow, II doesn''t follow', 'All engineers are problem-solvers (A→B). Some problem-solvers are creative (B⊕C). We cannot definitively conclude some engineers are creative; it''s possible but not certain.
 Conclusion I may follow.
 Conclusion II reverses the relationship and is not stated.
 Only I may follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f1');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f1', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f1', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f1');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f2', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''All successful entrepreneurs are risk-takers.'' Conclusions: I. Some risk-takers are successful entrepreneurs. II. Risk-taking leads to success.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Only I follows', 'From ''All successful entrepreneurs are risk-takers'', Conclusion I ''Some risk-takers are successful entrepreneurs'' definitely follows.
 Conclusion II reverses causation and introduces external logic not stated.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f2');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f2', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f2', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f2');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f3', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''Athletes who consume protein supplements improve their performance.'' Conclusions: I. Not all athletes consume protein supplements. II. All athletes who improve performance consume protein. III. Consuming protein supplements guarantees performance improvement.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Only I and II follow", "I and III follow", "None follow"]}', 'Only I follows', 'From the statement, we can infer that those who consume supplements improve (A→B), but not all athletes necessarily do so.
 Conclusion I follows logically.
 Conclusion II reverses the implication incorrectly.
 Conclusion III overstates causation.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f3');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f3', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f3', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f3');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f4', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statements: (1) All managers are decision-makers. (2) Some decision-makers are not leaders. (3) All leaders are visionaries. Conclusions: I. Some managers are not visionaries. II. Some managers are leaders. III. Some decision-makers are not visionaries. IV. All visionaries are leaders.', 'MCQ', 'HARD', '{"options": ["I and III follow", "II and IV follow", "Only I follows", "Only III follows", "I, III may follow; II, IV don''t follow"]}', 'Only III follows', 'I. Some managers are not visionaries → Possible but not definite (managers → decision-makers, could all be leaders/visionaries)
II. Some managers are leaders → Possible but not definite (no direct link)
III. Some decision-makers are not visionaries → Follows (decision-makers not leaders + leaders → visionaries → some decision-makers (not leaders) could be not visionaries)
IV. All visionaries are leaders → Doesn''t follow (visionaries ← leaders, not vice versa)
The answer is Only III follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f4');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f4', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f4', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f4');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f5', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statements: (1) Most employees in the company are skilled. (2) The company is profitable. Conclusions: I. The company is profitable because employees are skilled. II. Some employees in the company are not skilled. III. Profitable companies usually have skilled employees.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "Only I and II follow", "Only II and III follow", "All three follow"]}', 'Only II follows', 'From ''Most are skilled'', Conclusion II ''Some are not skilled'' logically follows (contrapositive of ''all'').
 Conclusion I assumes causation between statements 1 and 2, which is not established.
 Conclusion III makes an external generalization.
 Only II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f5');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f5', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f5', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f5');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f6', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''Some doctors are women.'' Conclusions: I. All doctors are women. II. Some women are doctors.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Only II follows', 'From ''Some doctors are women'', by conversion, ''Some women are doctors'' (Conclusion II) definitely follows.
 Conclusion I overgeneralizes—the statement doesn''t say all doctors are women.
 Only II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f6');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f6', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f6', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f6');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f7', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statements: (1) All artists are creative. (2) Some creative people are not writers. (3) No writer is uncreative. Conclusions: I. Some artists are not writers. II. All writers are creative. III. Some non-writers are creative.', 'MCQ', 'HARD', '{"options": ["I and II follow", "II and III follow", "I and III follow", "All three follow", "Only II follows"]}', 'II and III follow', 'All artists are creative (A→B). No writer is uncreative means all writers are creative (C→B). From statement 2, some creative are not writers.
 Conclusion I cannot be definitively drawn from artists'' perspective.
 Conclusion II follows from statement 3.
 Conclusion III follows from statement 2.
 Only II and III follow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f7');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f7', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f7', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f7');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f8', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''All birds have wings.'' Conclusions: I. Some birds have wings. II. All animals have wings.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II doesn''t follow"]}', 'Only I follows', 'From ''All birds have wings'', we can deduce ''Some birds have wings'' (universal implies particular). Conclusion I definitely follows.
 Conclusion II introduces new information about all animals, which is not stated.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f8');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f8', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f8', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f8');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f9', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''If a student studies hard, then they score well. Rajesh did not score well.'' Conclusions: I. Rajesh did not study hard. II. Some students who study hard score well. III. Rajesh may have studied hard.', 'MCQ', 'HARD', '{"options": ["Only I follows", "Only II follows", "I and II follow", "II and III follow", "Only III follows"]}', 'Only I follows', 'By contrapositive logic: If hard study → good score, then not good score → not hard study.
 Conclusion I follows.
 Conclusion II generalizes beyond the statement.
 Conclusion III contradicts the contrapositive.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f9');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f9', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000f9', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000f9');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fa', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''The school increased fees to improve infrastructure.'' Conclusions: I. Infrastructure improvement depends on fee increase. II. All schools will increase fees.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II doesn''t follow"]}', 'Only I follows', 'The statement shows the purpose/reason for fee increase is infrastructure improvement, supporting Conclusion I.
 Conclusion II generalizes to all schools without justification.
 Only I follows from the given statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fa');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fa', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fa', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fa');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fb', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statements: (1) All doctors are educated. (2) No educated person is unskilled. Conclusions: I. No doctor is unskilled. II. All unskilled people are doctors.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I follows, II may follow"]}', 'Only I follows', 'All doctors are educated (A→B). No educated is unskilled (B×C). By transitivity: No doctor is unskilled (A×C).
 Conclusion I follows.
 Conclusion II reverses the logic incorrectly.
 Only I follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fb');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fb', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fb', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fb');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fc', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''No fish are mammals.'' Conclusions: I. Some fish are not mammals. II. No mammals are fish.', 'MCQ', 'EASY', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "Only I or II may follow"]}', 'Both I and II follow', 'From ''No fish are mammals'', Conclusion I follows (negation implies some not).
 By conversion rule, ''No mammals are fish'' (Conclusion II) also follows.
 Both I and II are definite conclusions from the statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fc');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fc', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fc', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fc');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fd', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''The company reduced working hours to improve employee wellbeing.'' Conclusions: I. Employee wellbeing is affected by working hours. II. All companies should reduce working hours.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II follows"]}', 'Only I follows', 'The company''s action (reducing hours for wellbeing) implies Conclusion I about the relationship.
 Conclusion II makes a generalization beyond what one company did.
 Only I follows from the given statement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fd');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fd', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fd', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fd');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fe', 'dddddddd-dddd-dddd-dddd-000000000011', 'Directions: In the following question, a statement is given followed by certain conclusions. Consider the given statement to be true even if it seems to be at variance with commonly known facts. Decide which of the given conclusions logically follow(s) from the statement. Statement: ''Most people prefer tea over coffee.'' Conclusions: I. All people prefer tea. II. Some people prefer coffee over tea.', 'MCQ', 'MEDIUM', '{"options": ["Only I follows", "Only II follows", "Both I and II follow", "Neither I nor II follows", "I may follow, II follows"]}', 'Only II follows', 'From ''Most prefer tea'', Conclusion I is false (not all).
 From ''Most prefer tea'', we can logically deduce some people do not prefer tea, meaning Conclusion II ''Some prefer coffee over tea'' follows.
 Only II follows.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fe');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fe', 'eeeeeeee-eeee-eeee-eeee-000000000011', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000fe', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000fe');

-- Decision Making -> topic Decision Making
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000012', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Decision Making', 'Involves evaluating facts and conditions to choose the most appropriate decision or action', 'MEDIUM', 24, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000012');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000012', 'dddddddd-dddd-dddd-dddd-000000000012', 'Decision Making Challenge', 'Apply decision making skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000012');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ff', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. As a manager, you notice your team consistently misses deadlines due to unclear project requirements. What is the best approach?', 'MCQ', 'MEDIUM', '{"options": ["Fire team members for poor performance", "Conduct a meeting to clarify roles, responsibilities, and requirements", "Assign more work to motivate them", "Ignore the issue and see if it improves", "Blame the team publicly to create urgency"]}', 'Conduct a meeting to clarify roles, responsibilities, and requirements', 'This addresses the root cause with fairness and professionalism.
 Clarifying requirements and responsibilities removes obstacles and improves performance.
 This logical, people-focused approach is far more effective than punitive or avoidant measures.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ff');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ff', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-0000000000ff', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-0000000000ff');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000100', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. During an exam, you notice your classmate trying to copy from your paper. What should you do?', 'MCQ', 'EASY', '{"options": ["Allow them to copy to help them", "Shift your paper immediately and inform the invigilator", "Warn them silently and continue", "Copy their answers later for revenge", "Do nothing and ignore it"]}', 'Shift your paper immediately and inform the invigilator', 'This maintains academic integrity and fairness.
 Informing the invigilator is the professional and ethical choice that upholds exam rules.
 Allowing cheating undermines fairness and violates examination protocols.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000100');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000100', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000100', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000100');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000101', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. Two senior colleagues assign you equally urgent but contradictory tasks simultaneously. What should you do?', 'MCQ', 'MEDIUM', '{"options": ["Ignore one task completely", "Ask both colleagues to rank the priority together or get manager''s guidance", "Complete both partially to show effort", "Blame one colleague for the conflict", "Work through the night to complete both fully"]}', 'Ask both colleagues to rank the priority together or get manager''s guidance', 'This demonstrates maturity and logical decision-making.
 Seeking clarification on priorities from both parties or manager prevents conflicts and ensures effective work.
 Ignoring tasks, doing poor work, or creating blame are unprofessional responses to this common workplace challenge.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000101');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000101', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000101', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000101');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000102', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You find a wallet containing money, credit cards, and an ID on the street. What is the best course of action?', 'MCQ', 'EASY', '{"options": ["Keep the money and discard the wallet", "Ignore it and walk away", "Contact the owner using the ID or inform local police to return it", "Post it on social media to find the owner", "Give it to a friend to sell online"]}', 'Contact the owner using the ID or inform local police to return it', 'This decision reflects ethical behavior and personal integrity.
 Contacting the owner or informing police is the most responsible action that ensures the property is returned to its rightful owner.
 Options A, B, D, and E are unethical or impractical.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000102');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000102', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000102', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000102');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000103', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. During promotions, your personal friend and a more qualified colleague are both candidates. The organization wants you to influence the decision. What should you do?', 'MCQ', 'HARD', '{"options": ["Advocate for your friend regardless of qualifications", "Recuse yourself from the process to avoid conflict of interest", "Present objective performance data for both and recommend the most qualified candidate", "Vote for your friend but try to help them improve later", "Remain silent and let someone else decide"]}', 'Present objective performance data for both and recommend the most qualified candidate', 'Sound judgment, responsibility, and professionalism demand fairness and meritocracy. Recusing yourself might avoid conflict but doesn''t serve the organization''s best interest. Advocating for your friend regardless of qualifications is unethical. Voting for your friend and helping them later is biased. Remaining silent is avoiding responsibility.
Presenting objective data ensures the best candidate is chosen while maintaining integrity.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000103');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000103', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000103', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000103');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000104', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. A businessman offers you money to speed up an official approval process that normally takes a month. What should you do?', 'MCQ', 'MEDIUM', '{"options": ["Accept the money and help him", "Refuse politely and report the incident to your supervisor", "Pretend to accept and later deny everything", "Ask for more money before deciding", "Accept but delay the approval anyway"]}', 'Refuse politely and report the incident to your supervisor', 'This upholds professional ethics and integrity.
 Refusing and reporting is the legally correct and morally sound decision.
 It maintains the integrity of official processes and protects both you and the organization.
 Other options involve corruption or dishonesty.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000104');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000104', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000104', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000104');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000105', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. A close friend asks you to share confidential company data that would help their startup. What should you do?', 'MCQ', 'MEDIUM', '{"options": ["Share the data to help your friend", "Refuse politely and explain why confidentiality is important", "Share only a small portion claiming it''s harmless", "Promise to share after you leave the company", "Ignore their request without explaining"]}', 'Refuse politely and explain why confidentiality is important', 'This maintains confidentiality and professional ethics.
 Refusing clearly while explaining the importance of data protection shows integrity and respect for agreements.
 Sharing confidential data, even partially or later, violates trust and legal obligations regardless of friendship.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000105');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000105', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000105', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000105');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000106', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. During a critical project, you discover a team member made a serious mistake that will miss the deadline unless it''s hidden from the client. Your manager suggests concealing it. What should you do?', 'MCQ', 'HARD', '{"options": ["Go along with the deception to meet the deadline", "Immediately inform the client and propose solutions", "Discuss with your manager why honesty is better long-term and jointly develop a transparent recovery plan", "Secretly inform the client without telling your manager", "Blame the team member to deflect responsibility"]}', 'Discuss with your manager why honesty is better long-term and jointly develop a transparent recovery plan', 'This balances professional respect with ethical responsibility.
 Engaging your manager in why transparency builds trust and prevents larger problems shows leadership.
 A joint solution demonstrates accountability and problem-solving.
 While initially painful, honest communication maintains relationships and organizational reputation better than deception would.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000106');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000106', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000106', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000106');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000107', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You see an elderly person struggling to carry heavy groceries across a busy street. What is the most appropriate action?', 'MCQ', 'EASY', '{"options": ["Continue walking; it''s not your responsibility", "Offer to help them carry the groceries", "Record them on your phone to post online", "Call someone else to help instead", "Wait and see if someone else helps"]}', 'Offer to help them carry the groceries', 'This demonstrates empathy and social responsibility.
 Offering direct help is the most practical and human approach.
 It reflects kindness, accountability, and the willingness to assist vulnerable people in need without seeking recognition.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000107');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000107', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000107', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000107');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000108', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You learn that your company''s product has a serious safety flaw that could harm customers, but reporting it could cause company bankruptcy and job losses. What is your ethical responsibility?', 'MCQ', 'HARD', '{"options": ["Stay silent to protect jobs", "Report the safety issue to appropriate authorities as customer safety is paramount", "Alert only the CEO privately and hope they handle it", "Leak information anonymously to the media", "Wait and see if customers complain first"]}', 'Report the safety issue to appropriate authorities as customer safety is paramount', 'Public safety and ethical responsibility supersede economic concerns.
 Reporting through proper channels protects customers and the organization legally.
 While job losses are regrettable, allowing harm to customers is fundamentally wrong.
 This demonstrates integrity despite personal consequences.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000108');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000108', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000108', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000108');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000109', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You are a team leader and two of your team members are having a heated argument that''s disrupting work. What should you do?', 'MCQ', 'MEDIUM', '{"options": ["Ignore it and let them resolve it themselves", "Take sides with the more senior employee", "Call a private meeting with both to understand issues and find a resolution calmly", "Scold both publicly to establish authority", "Report both to HR without investigating first"]}', 'Call a private meeting with both to understand issues and find a resolution calmly', 'As a leader, addressing conflict privately and fairly is the most professional approach.
 Understanding both perspectives before taking action demonstrates good leadership, fairness, and problem-solving skills.
 Public scolding or immediate HR involvement without investigation are extreme and unprofessional.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000109');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000109', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000109', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000109');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010a', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You are running 15 minutes late for an important team meeting with your manager. What should you do?', 'MCQ', 'EASY', '{"options": ["Skip the meeting entirely", "Inform your manager immediately and join as soon as possible", "Arrive quietly without apologizing or explaining", "Send a colleague to cover for you", "Tell the manager you had an emergency and won''t attend"]}', 'Inform your manager immediately and join as soon as possible', 'Professional communication and responsibility are key.
 Informing the manager promptly demonstrates respect and accountability.
 This is the most honest and professional approach compared to other options which involve dishonesty or neglect of duty.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010a', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010a', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010b', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. You discover that your mentor (who helped your career) is engaging in unethical practices that harm the organization. However, reporting could damage their career. What should you do?', 'MCQ', 'HARD', '{"options": ["Say nothing to protect their career", "First speak privately with your mentor about the behavior and give them a chance to correct it", "Immediately report to higher authorities without discussion", "Participate in the unethical practice to show loyalty", "Spread rumors about it instead of formal reporting"]}', 'First speak privately with your mentor about the behavior and give them a chance to correct it', 'This balances loyalty with ethics and professional responsibility.
 A private conversation first gives the mentor an opportunity to correct the behavior and demonstrates respect.
 If behavior continues, formal reporting becomes necessary.
 This thoughtful approach is more ethical than either blind loyalty or immediate escalation without dialogue.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010b', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010b', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010c', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. Your boss asks you to complete a task in one day that typically takes three days. You realize it''s impossible. What should you do?', 'MCQ', 'EASY', '{"options": ["Say ''yes'' and then miss the deadline", "Refuse outright and become defensive", "Communicate the timeline realistically and suggest a feasible plan", "Pretend to work and submit incomplete work", "Delegate the task to a junior colleague without permission"]}', 'Communicate the timeline realistically and suggest a feasible plan', 'This response combines honesty, professionalism, and practical problem-solving.
 By clearly communicating constraints and offering alternatives, you maintain trust and credibility.
 Other options involve dishonesty or irresponsibility.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010c', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010c', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010d', 'dddddddd-dddd-dddd-dddd-000000000012', 'Directions: In the following question, a situation is presented along with several possible responses. You must select the most appropriate and sensible response that demonstrates sound judgment, responsibility, and professionalism in the given situation. Your organization has limited budget. You can either invest in employee training (long-term benefit) or immediate bonuses (short-term satisfaction). Senior management pushes for bonuses. What should you recommend?', 'MCQ', 'HARD', '{"options": ["Recommend only bonuses to please management", "Recommend only training regardless of management pressure", "Present both options with analysis of long-term and short-term impacts, then recommend a balanced approach", "Avoid making a decision and defer to management entirely", "Recommend both without checking budget constraints"]}', 'Present both options with analysis of long-term and short-term impacts, then recommend a balanced approach', 'This demonstrates strategic thinking and responsibility.
 Presenting data-driven analysis with both perspectives shows professional judgment.
 Balancing short-term satisfaction with long-term organizational growth is more valuable than either extreme.
 This approach maintains credibility while supporting informed decision-making.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010d', 'eeeeeeee-eeee-eeee-eeee-000000000012', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010d', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010d');

-- In-Equalities -> topic In-Equalities
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000013', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'In-Equalities', 'Solves problems involving comparison of quantities using inequality symbols and logical deduction', 'MEDIUM', 25, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000013');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000013', 'dddddddd-dddd-dddd-dddd-000000000013', 'In-Equalities Challenge', 'Apply in-equalities skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000013');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010e', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: A = B, B ≥ C, C > D. Conclusions: (i) A > D (ii) D < B. Which follow?', 'MCQ', 'HARD', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: U ≤ V means U is either equal to V or less than V. Step 2: So either conclusion (i) or (ii) may be true but not both necessarily. Final Answer: Either (i) or (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010e', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010e', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010f', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: R > S ≥ T, U = T, V < U. Conclusions: (i) R > V (ii) S ≥ V. Which follow?', 'MCQ', 'HARD', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: X ≥ Y and Y ≥ Z ⇒ X ≥ Z by transitivity. Step 2: Z ≤ X is equivalent to X ≥ Z. Both follow. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010f', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000010f', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000010f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000110', 'dddddddd-dddd-dddd-dddd-000000000013', 'Given: ‘@’ means ‘≥’, ‘#’ means ‘>’. Statements: A @ B, B # C. Conclusions: (i) A > C (ii) C ≤ A. Which follow?', 'MCQ', 'MEDIUM', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: Decode: X ≥ Y and Y < Z. Step 2: From X ≥ Y and Y < Z we cannot conclude X ≥ Z. Step 3: Z > X also not guaranteed. Final Answer: Cannot be determined.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000110');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000110', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000110', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000110');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000111', 'dddddddd-dddd-dddd-dddd-000000000013', 'Given: ‘$’ means ‘<’ and ‘&’ means ‘=’. Statements: X $ Y, Y & Z. Conclusions: (i) X < Z (ii) Z > X. Which follow?', 'MCQ', 'MEDIUM', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: From A > B ≥ C > D ⇒ A > C and C > D ⇒ A > D. Step 2: B ≥ C and C > D ⇒ B > D. Both conclusions follow. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000111');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000111', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000111', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000111');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000112', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: P > Q, Q = R, R < S. Conclusions: (i) P > S (ii) Q < S. Which follow?', 'MCQ', 'MEDIUM', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Only (ii)', 'Step 1: From N = O and O < P ⇒ N < P. Step 2: P ≤ Q ⇒ N < P ≤ Q ⇒ N < Q. Step 3: M ≥ N and N < Q ⇒ M may or may not be < Q. Only (ii) follows. Final Answer: Only (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000112');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000112', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000112', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000112');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000113', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: A > B, B > C. Conclusions: (i) A > C (ii) C < A. Which follow?', 'MCQ', 'EASY', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: A = B, B ≥ C, C > D ⇒ B ≥ C > D ⇒ B > D. Step 2: If B > D and A = B ⇒ A > D. Step 3: D < B follows from B > D. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000113');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000113', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000113', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000113');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000114', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: A > B ≥ C > D. Conclusions: (i) A > D (ii) B > D. Which follow?', 'MCQ', 'MEDIUM', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: From Q = R and R < S ⇒ Q < S. Step 2: From P > Q and Q < S we cannot deduce relation between P and S. Thus only (ii) follows. Final Answer: Only (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000114');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000114', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000114', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000114');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000115', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: P = Q, Q > R. Conclusions: (i) P > R (ii) R < P. Which follow?', 'MCQ', 'EASY', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: A ≥ B means A is either equal to or greater than B. Step 2: So either A = B or A > B must be true, but not both necessarily. Final Answer: Either (i) or (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000115');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000115', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000115', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000115');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000116', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: U ≤ V. Conclusions: (i) U = V (ii) U < V. Which follow?', 'MCQ', 'MEDIUM', '{"options": ["Only (i)", "Only (ii)", "Either (i) or (ii)", "Both (i) and (ii)", "Neither"]}', 'Either (i) or (ii)', 'Step 1: From S ≥ T and U = T ⇒ S ≥ U. Step 2: V < U ⇒ V < U ≤ S ⇒ S > V ⇒ S ≥ V. Step 3: R > S and S > V ⇒ R > V. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000116');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000116', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000116', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000116');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000117', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: X ≥ Y, Y ≥ Z. Conclusions: (i) X ≥ Z (ii) Z ≤ X. Which follow?', 'MCQ', 'EASY', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Both (i) and (ii)', 'Step 1: Decode: A > B, B ≤ C, C > D. Step 2: From B ≤ C and C > D ⇒ B may be > D or ≤ D; uncertain. Step 3: From A > B and B ≤ C ⇒ A may or may not be > C. Hence neither conclusion is definite. Final Answer: Cannot be determined.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000117');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000117', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000117', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000117');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000118', 'dddddddd-dddd-dddd-dddd-000000000013', 'Given: ‘@’ means ‘>’, ‘#’ means ‘≤’. Statements: A @ B, B # C, C @ D. Conclusions: (i) A > C (ii) B ≤ D. Which follow?', 'MCQ', 'HARD', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Cannot be determined', 'Step 1: Given A > B and B > C. Step 2: By transitivity A > C. Step 3: C < A is equivalent to A > C. Hence both (i) and (ii) follow. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000118');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000118', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000118', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000118');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000119', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: M > N, O < P. Conclusions: (i) M > O (ii) N < P. Which follow?', 'MCQ', 'EASY', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Cannot be determined', 'Step 1: Decode: A ≥ B and B > C. Step 2: From A ≥ B and B > C ⇒ A > C. Step 3: C ≤ A is same as A ≥ C, which follows from A > C. Both conclusions follow. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000119');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000119', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000119', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000119');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011a', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: M ≥ N, N = O, O < P, P ≤ Q. Conclusions: (i) M < Q (ii) N < Q. Which follow?', 'MCQ', 'HARD', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Only (ii)', 'Step 1: P = Q and Q > R ⇒ P > R (replace Q by P). Step 2: R < P is same as P > R. Both conclusions are true. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011a', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011a', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011b', 'dddddddd-dddd-dddd-dddd-000000000013', 'Statements: A ≥ B. Conclusions: (i) A = B (ii) A > B. Which follows?', 'MCQ', 'EASY', '{"options": ["Only (i)", "Only (ii)", "Either (i) or (ii)", "Both (i) and (ii)", "Neither"]}', 'Either (i) or (ii)', 'Step 1: Decode: X < Y and Y = Z. Step 2: Since Y = Z, X < Y implies X < Z. Step 3: Z > X is same as X < Z. Both conclusions follow. Final Answer: Both (i) and (ii).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011b', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011b', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011c', 'dddddddd-dddd-dddd-dddd-000000000013', 'Given: ‘$’ means ‘≥’, ‘%’ means ‘<’. Statements: X $ Y, Y % Z. Conclusions: (i) X ≥ Z (ii) Z > X. Which follow?', 'MCQ', 'HARD', '{"options": ["Only (i)", "Only (ii)", "Both (i) and (ii)", "Neither", "Cannot be determined"]}', 'Cannot be determined', 'Step 1: The pairs (M,N) and (O,P) are unrelated — no link between M and O or N and P. Step 2: Cannot deduce either relation. Final Answer: Cannot be determined.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011c', 'eeeeeeee-eeee-eeee-eeee-000000000013', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011c', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011c');

-- Puzzles -> topic Puzzles
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000014', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Puzzles', 'Involves logical problem-solving using given conditions, arrangements, and constraints', 'MEDIUM', 26, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000014');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000014', 'dddddddd-dddd-dddd-dddd-000000000014', 'Puzzles Challenge', 'Apply puzzles skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000014');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011d', 'dddddddd-dddd-dddd-dddd-000000000014', 'Five lectures (A, B, C, D, E) are scheduled from Monday to Friday. Lecture C is on Wednesday. Lecture B is scheduled immediately before C. There is exactly one lecture scheduled between B and D. Lecture E is not scheduled on Monday. Which lecture is scheduled on Friday?', 'MCQ', 'MEDIUM', '{"options": ["D", "A", "C", "E", "B"]}', 'E', 'Step 1: The schedule is for Monday, Tuesday, Wednesday, Thursday, Friday. Step 2: Lecture C is on Wednesday. (C = Wed). Step 3: Lecture B is scheduled immediately before C. (B = Tue). Step 4: There is exactly one lecture scheduled between B (on Tue) and D. This means D must be on Thursday (with C in between). (D = Thu). Step 5: The remaining days are Monday and Friday. The remaining lectures are A and E. Step 6: Lecture E is not scheduled on Monday. Therefore, E must be scheduled on Friday. (E = Fri). Step 7: This leaves Lecture A, which must be scheduled on Monday. (A = Mon). Step 8: Final Schedule: A(Mon), B(Tue), C(Wed), D(Thu), E(Fri). Step 9: The lecture scheduled on Friday is E. Correct Answer: E', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011d', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011d', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011e', 'dddddddd-dddd-dddd-dddd-000000000014', 'Seven boxes, A, B, C, D, E, F, and G, are stacked. Box E is third from the top. Box B is placed immediately below E. There are two boxes between B and C. Box A is placed immediately above Box G. Box F is placed somewhere above Box D. Box C is not placed at the bottom. Which box is at the bottom?', 'MCQ', 'MEDIUM', '{"options": ["C", "F", "G", "D", "A"]}', 'D', 'Step 1: There are $7$ positions, let $1$ be the bottom and $7$ be the top. Step 2: Box E is third from the top. Position = $7 - 2 = 5$. (E = $5$). Step 3: Box B is immediately below E. (B = $4$). Step 4: There are two boxes between B (at $4$) and C. C could be at position $1$ ($4-3$) or position $7$ ($4+3$). Step 5: The clue states C is not at the bottom (C $\neq 1$). Therefore, C must be at the top. (C = $7$). Step 6: Box A is immediately above Box G (A = G+$1$). This is an ''A-G'' block. The available empty slots are $1, 2, 3, 6$. The ''A-G'' block must fit in adjacent slots $2$ and $3$. (A = $3$, G = $2$). Step 7: The remaining slots are $1$ and $6$. The remaining boxes are F and D. Step 8: Box F is placed above Box D ($F > D$). Therefore, F must be at $6$ and D at $1$. Step 9: Final Stack (bottom to top): D($1$), G($2$), A($3$), B($4$), E($5$), F($6$), C($7$). Step 10: The box at the bottom (position $1$) is D. Correct Answer: D', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011e', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011e', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011f', 'dddddddd-dddd-dddd-dddd-000000000014', 'Four people—P, Q, R, and S—live on four different floors ($1$=bottom, $4$=top). S lives on the lowest floor (Floor $1$). R lives on an even-numbered floor. P lives immediately above R. Who lives on floor $3$?', 'MCQ', 'EASY', '{"options": ["P", "Q", "R", "S", "Cannot be determined"]}', 'P', 'Step 1: The floors are $1$ (bottom), $2$, $3$, and $4$ (top). Step 2: S lives on Floor $1$. (S = $1$). Step 3: R lives on an even-numbered floor (either $2$ or $4$). Step 4: P lives immediately above R (P = R+$1$). Step 5: If R = $4$, P would be on Floor $5$, which is not possible. Step 6: Therefore, R must be on Floor $2$. (R = $2$). Step 7: P lives immediately above R, so P is on Floor $3$. (P = $3$). Step 8: The only remaining person, Q, must live on Floor $4$. (Q = $4$). Step 9: The final arrangement (bottom to top) is: S($1$), R($2$), P($3$), Q($4$). Correct Answer: P', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011f', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000011f', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000011f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000120', 'dddddddd-dddd-dddd-dddd-000000000014', 'Six people (P, Q, R, S, T, U) live on six different floors of a building ($1$=bottom, $6$=top). S lives on Floor $1$. There are two floors between S and P. U lives on an even-numbered floor. T lives immediately above U. Q lives on a floor above R. Who lives on Floor $5$?', 'MCQ', 'MEDIUM', '{"options": ["P", "R", "T", "U", "Q"]}', 'R', 'Step 1: The floors are numbered $1$ (bottom) to $6$ (top). Step 2: S lives on Floor $1$. (S = $1$). Step 3: There are two floors ($2$ and $3$) between S (on $1$) and P. This means P must live on Floor $4$. (P = $4$). Step 4: U lives on an even-numbered floor. The available even floors are $2$ and $6$ (since $4$ is taken by P). Step 5: T lives immediately above U (T = U+$1$). If U = $6$, T would be on Floor $7$, which is impossible. Step 6: Therefore, U must live on Floor $2$. (U = $2$). Step 7: T lives immediately above U, so T lives on Floor $3$. (T = $3$). Step 8: The remaining floors are $5$ and $6$. The remaining people are Q and R. Step 9: Q lives on a floor above R ($Q > R$). Therefore, Q must be on Floor $6$ and R on Floor $5$. Step 10: Final Order (bottom to top): S($1$), U($2$), T($3$), P($4$), R($5$), Q($6$). Step 11: The person living on Floor $5$ is R. Correct Answer: R', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000120');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000120', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000120', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000120');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000121', 'dddddddd-dddd-dddd-dddd-000000000014', 'Eight people (A-H) sit at a square table, four at corners and four in the middle of the sides, all facing center. A sits in the middle of a side. B sits opposite A. C is to the immediate right of B. D is at a corner and sits opposite E. F sits adjacent to A. Who sits opposite F?', 'MCQ', 'MEDIUM', '{"options": ["C", "E", "G", "D", "H"]}', 'C', 'Step 1: All $8$ people face the center. A sits in a middle seat. B sits opposite A, so B is also in a middle seat. Step 2: Let''s place A at the Bottom-Middle. B is at the Top-Middle. Step 3: C is to the immediate right of B. B (at Top-Middle) is facing center (down), so B''s right is the Top-Left corner. (C = Top-Left corner). Step 4: D is a corner and sits opposite E (who must also be a corner). The four corners are Top-Left, Top-Right, Bottom-Left, Bottom-Right. C already occupies the Top-Left corner. The only remaining pair of opposite corners is (Top-Right, Bottom-Left). Step 5: So, $\{D, E\}$ must occupy the $\{Top-Right, Bottom-Left\}$ corners. Step 6: F sits adjacent to A (at Bottom-Middle). The adjacent seats to A are the Bottom-Left and Bottom-Right corners. Step 7: Since the Bottom-Left corner is occupied by either D or E, F must occupy the Bottom-Right corner. (F = Bottom-Right corner). Step 8: The question asks who sits opposite F. F is at the Bottom-Right corner. The seat opposite the Bottom-Right corner is the Top-Left corner. Step 9: From Step 3, we know C sits at the Top-Left corner. Therefore, C sits opposite F. Correct Answer: C', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000121');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000121', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000121', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000121');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000122', 'dddddddd-dddd-dddd-dddd-000000000014', 'Three people—Alok, Ben, and Chris—are each from one of three cities: Delhi, Mumbai, or Kolkata. Ben is from Kolkata. Alok is not from Mumbai. Who is from Delhi?', 'MCQ', 'EASY', '{"options": ["No one", "Ben", "Chris", "Alok", "Cannot be determined"]}', 'Alok', 'Step 1: We have three people (Alok, Ben, Chris) and three cities (Delhi, Mumbai, Kolkata). Step 2: Ben is from Kolkata. (Ben = Kolkata). Step 3: The remaining people are Alok and Chris. The remaining cities are Delhi and Mumbai. Step 4: We are told Alok is not from Mumbai. Step 5: Therefore, Alok must be from Delhi. (Alok = Delhi). Step 6: This leaves Chris, who must be from Mumbai. (Chris = Mumbai). Correct Answer: Alok', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000122');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000122', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000122', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000122');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000123', 'dddddddd-dddd-dddd-dddd-000000000014', 'Four people—A, B, C, and D—are sitting at a square table, one on each side, facing the center. A sits opposite D. B is to the immediate left of D. Who sits opposite B?', 'MCQ', 'EASY', '{"options": ["A", "B", "C", "D", "Cannot be determined"]}', 'C', 'Step 1: Draw a square. Place the four people (A, B, C, D) on the four sides, all facing the center. Step 2: A sits opposite D. Let''s place A at the top side and D at the bottom side. Step 3: B is to the immediate left of D. Since D is at the bottom and facing the center (upwards), his immediate left is the right-hand side of the table. Step 4: So, B sits on the right side. Step 5: The only remaining person is C, and the only remaining seat is the left-hand side. So, C sits on the left side. Step 6: The person sitting opposite B (who is on the right side) is C (who is on the left side). Correct Answer: C', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000123');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000123', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000123', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000123');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000124', 'dddddddd-dddd-dddd-dddd-000000000014', 'Seven boxes (A, B, C, D, E, F, G) are stacked one above another ($1$=bottom, $7$=top). Box A is fourth from the bottom. There are two boxes between A and D. Box G is placed immediately above D. Box B is placed immediately above Box C. Box F is not placed at the top. Who is at the top?', 'MCQ', 'HARD', '{"options": ["D", "E", "F", "B", "C"]}', 'E', 'Step 1: There are $7$ positions, let $1$ be the bottom and $7$ be the top. Step 2: Box A is fourth from the bottom. (A = $4$). Step 3: There are two boxes between A (at $4$) and D. D can be at position $1$ ($4-3$) or position $7$ ($4+3$). Step 4: Box G is placed immediately above D (G = D+$1$). Step 5: If D = $7$, G would be at $8$, which is impossible. Therefore, D must be at $1$. (D = $1$). Step 6: G is immediately above D, so G is at $2$. (G = $2$). Step 7: The occupied slots are $1$(D), $2$(G), and $4$(A). The empty slots are $3, 5, 6, 7$. Step 8: Box B is placed immediately above Box C (a ''B-C'' block). This block needs two adjacent empty slots. The only available pair is $5$ and $6$. So, B = $6$ and C = $5$. Step 9: The occupied slots are now $1$(D), $2$(G), $4$(A), $5$(C), $6$(B). The empty slots are $3$ and $7$. Step 10: The remaining boxes are E and F. Step 11: Box F is not placed at the top (F $\neq 7$). Therefore, F must be at position $3$. (F = $3$). Step 12: This leaves Box E for the last remaining slot, position $7$. (E = $7$). Step 13: Final Stack (bottom to top): D($1$), G($2$), F($3$), A($4$), C($5$), B($6$), E($7$). Step 14: The box at the top is E. Correct Answer: E', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000124');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000124', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000124', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000124');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000125', 'dddddddd-dddd-dddd-dddd-000000000014', 'Three friends—Tom, Ria, and Sam—have exams on three consecutive days (Monday, Tuesday, Wednesday). Sam''s exam is on Wednesday. Ria''s exam is not on Monday. On which day is Tom''s exam?', 'MCQ', 'EASY', '{"options": ["Tuesday", "Sam''s Day", "Monday", "Wednesday", "Cannot be determined"]}', 'Monday', 'Step 1: The three consecutive days are Monday, Tuesday, and Wednesday. Step 2: Sam''s exam is on Wednesday. (Sam = Wednesday). Step 3: The remaining days are Monday and Tuesday. Ria''s exam is not on Monday. Step 4: Therefore, Ria''s exam must be on Tuesday. (Ria = Tuesday). Step 5: The only remaining person is Tom, and the only remaining day is Monday. Step 6: Therefore, Tom''s exam is on Monday. (Tom = Monday). Correct Answer: Monday', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000125');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000125', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000125', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000125');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000126', 'dddddddd-dddd-dddd-dddd-000000000014', 'Seven people (A-G) have exams in seven different months (Jan, Feb, Mar, Apr, May, Jun, Jul). C''s exam is in February. There are three months between C''s exam and B''s exam. G''s exam is immediately after B''s. E''s exam is in a month with $30$ days, but not June. A''s exam is in a month with $31$ days. F''s exam is scheduled after D''s exam. D''s exam is not in January. Who has an exam in May?', 'MCQ', 'HARD', '{"options": ["A", "B", "D", "E", "F"]}', 'F', 'Step 1: List the months and day counts: Jan($31$), Feb, Mar($31$), Apr($30$), May($31$), Jun($30$), Jul($31$). Step 2: C''s exam is in February. (C = Feb). Step 3: There are three months (March, April, May) between C (Feb) and B. This means B''s exam is in June. (B = Jun). Step 4: G''s exam is immediately after B (Jun). So, G''s exam is in July. (G = Jul). Step 5: E''s exam is in a $30$-day month, but not June. The only other $30$-day month in the list is April. (E = Apr). Step 6: Months taken: Feb(C), Apr(E), Jun(B), Jul(G). Step 7: Remaining months: January, March, May. Remaining people: A, D, F. Step 8: D''s exam is not in January. So D must be in March or May. Step 9: F''s exam is scheduled after D''s exam ($F > D$). Step 10: If D = May, F cannot be scheduled after D. This is impossible. Step 11: Therefore, D must be in March. (D = Mar). Step 12: Since F > D (Mar), F must be in May. (F = May). Step 13: The only remaining person, A, must be in the only remaining month, January. (A = Jan). Step 14: Check A''s rule: A''s exam is in a $31$-day month. A=Jan, which has $31$ days. This is correct. Step 15: Final Schedule: A(Jan), C(Feb), D(Mar), E(Apr), F(May), B(Jun), G(Jul). Step 16: The person with an exam in May is F. Correct Answer: F', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000126');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000126', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000126', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000126');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000127', 'dddddddd-dddd-dddd-dddd-000000000014', 'Five boxes—A, B, C, D, and E—are stacked vertically. C is at the top. A is immediately below C. B is at the bottom. E is stacked somewhere above D. Which box is in the middle (third from top or bottom)?', 'MCQ', 'EASY', '{"options": ["B", "D", "A", "C", "E"]}', 'E', 'Step 1: There are $5$ positions, let $1$ be the bottom and $5$ be the top. Step 2: C is at the top. (C = $5$). Step 3: A is immediately below C. (A = $4$). Step 4: B is at the bottom. (B = $1$). Step 5: The remaining positions are $2$ and $3$. The remaining boxes are D and E. Step 6: E is stacked above D ($E > D$). Therefore, E must be at position $3$ and D at position $2$. Step 7: The final stack (bottom to top) is: B($1$), D($2$), E($3$), A($4$), C($5$). Step 8: The middle box (position $3$) is E. Correct Answer: E', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000127');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000127', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000127', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000127');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000128', 'dddddddd-dddd-dddd-dddd-000000000014', 'Eight people (A-H) sit at a square table. Four sit at corners (facing out), four sit in the middle of sides (facing in). A sits in a middle seat. H sits second to the right of A. B sits opposite H. C is at a corner and is an immediate neighbor of B. D is not an immediate neighbor of A. E sits opposite G. Who sits opposite A?', 'MCQ', 'HARD', '{"options": ["H", "C", "D", "F", "B"]}', 'D', 'Step 1: Set up the table. Middle seats (M) face IN. Corner seats (K) face OUT. A is in a middle seat. Let A = Bottom-Middle (BM, facing IN). Step 2: H is second to the right of A. A (facing IN) 1st right is Bottom-Left (BL, facing OUT). 2nd right is Left-Middle (LM, facing IN). So, H = Left-Middle. Step 3: B sits opposite H (LM). B must be at Right-Middle (RM, facing IN). Step 4: C is a corner and a neighbor of B (RM). B''s neighbors are Top-Right (TR) and Bottom-Right (BR) corners. So C = TR or C = BR. Step 5: D is not an immediate neighbor of A (BM). A''s neighbors are BL and BR corners. So D $\neq$ BL and D $\neq$ BR. Step 6: E sits opposite G. The opposite pairs are: (BM, TM), (LM, RM), (TL, BR), (TR, BL). We know (A, ?), (H, B), so E and G must be a corner pair: $\{E, G\} = \{TL, BR\}$ or $\{E, G\} = \{TR, BL\}$. Step 7: **Case 1: Assume C = TR (from Step 4).** - The corner pair $\{TR, BL\}$ is now $\{C, BL\}$. So $\{E, G\}$ cannot be this pair. - $\{E, G\}$ must be the other corner pair: $\{TL, BR\}$. - Seats taken: A(BM), B(RM), H(LM), C(TR), E/G(TL), E/G(BR). - Remaining seats: Top-Middle (TM) and Bottom-Left (BL). - Remaining people: D, F. - From Step 5, D $\neq$ BL. Therefore, D must be at Top-Middle (TM). - This leaves F for the Bottom-Left (BL) seat. This case is valid. Step 8: **Case 2: Assume C = BR (from Step 4).** - The corner pair $\{TL, BR\}$ is now $\{TL, C\}$. So $\{E, G\}$ cannot be this pair. - $\{E, G\}$ must be the other corner pair: $\{TR, BL\}$. - Seats taken: A(BM), B(RM), H(LM), C(BR), E/G(TR), E/G(BL). - From Step 5, D $\neq$ BL and D $\neq$ BR. But C is at BR and E/G is at BL. This rule is satisfied as D is not C or E/G. - Remaining seats: Top-Middle (TM) and Top-Left (TL). Remaining people: D, F. D could be TM or TL. This case is ambiguous and thus invalid. Step 9: Following the only valid path (Case 1), D sits at Top-Middle. Step 10: The question asks who sits opposite A (at Bottom-Middle). The person opposite is D (at Top-Middle). Correct Answer: D', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000128');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000128', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000128', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000128');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000129', 'dddddddd-dddd-dddd-dddd-000000000014', 'Seven people (A, B, C, D, E, F, G) live on seven different floors ($1$=bottom, $7$=top). A lives on Floor $4$. C lives on an odd-numbered floor above A, but not on the top floor. There is one floor between C and B. G lives on the bottom floor. D lives immediately above G. F lives on an even-numbered floor, but not Floor $2$. B lives on a floor above E. Who lives on Floor $5$?', 'MCQ', 'HARD', '{"options": ["B", "F", "E", "A", "C"]}', 'C', 'Step 1: The floors are numbered $1$ (bottom) to $7$ (top). Step 2: G lives on the bottom floor. (G = $1$). Step 3: D lives immediately above G. (D = $2$). Step 4: A lives on Floor $4$. (A = $4$). Step 5: C lives on an odd-numbered floor above A (floor $4$) but not on the top floor (floor $7$). The only odd floor between $4$ and $7$ (exclusive of $7$) is $5$. (C = $5$). Step 6: There is one floor between C (at $5$) and B. This means B can be on Floor $3$ or Floor $7$. Step 7: F lives on an even-numbered floor, but not Floor $2$. The available even floors are $4$ and $6$. Since A is on $4$, F must be on $6$. (F = $6$). Step 8: The floors taken are $1$(G), $2$(D), $4$(A), $5$(C), $6$(F). The remaining floors are $3$ and $7$. The remaining people are B and E. Step 9: From Step 6, B must be $3$ or $7$. From Step 8, B and E occupy floors $3$ and $7$. Step 10: The clue states B lives on a floor above E ($B > E$). Step 11: If B = $3$, then E = $7$. This violates $B > E$. Step 12: Therefore, B must be $7$ and E must be $3$. This satisfies $B > E$. Step 13: Final Order (bottom to top): G($1$), D($2$), E($3$), A($4$), C($5$), F($6$), B($7$). Step 14: The person living on Floor $5$ is C. Correct Answer: C', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000129');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000129', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000129', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000129');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012a', 'dddddddd-dddd-dddd-dddd-000000000014', 'Four people (A, B, C, D) each have a different profession (Doctor, Engineer, Lawyer, Teacher) and a different favorite color (Red, Blue, Green, Yellow). A is the Doctor. C is the Engineer and likes Blue. The Lawyer likes Green. B likes Red and is not the Lawyer. Who is the Teacher?', 'MCQ', 'HARD', '{"options": ["A", "B", "C", "D", "Cannot be determined"]}', 'B', 'Step 1: Create a table to map People (A, B, C, D) to Professions (Doc, Eng, Law, Tea) and Colors (Red, Blu, Grn, Yel). Step 2: A is the Doctor. (A = Doctor). Step 3: C is the Engineer and likes Blue. (C = Engineer, C = Blue). Step 4: We have a fixed pair: (Lawyer = Green). Step 5: B likes Red. (B = Red). B is not the Lawyer. Step 6: The remaining professions for B and D are Lawyer and Teacher. Since B is not the Lawyer, B must be the Teacher. (B = Teacher). Step 7: The only remaining person, D, must be the Lawyer. (D = Lawyer). Step 8: From Step 4, the Lawyer (D) likes Green. (D = Green). Step 9: From Step 5, B (the Teacher) likes Red. (B = Red). Step 10: The only remaining color is Yellow, which must belong to A (the Doctor). (A = Yellow). Step 11: Final matches: A(Doctor, Yellow), B(Teacher, Red), C(Engineer, Blue), D(Lawyer, Green). Step 12: The question asks who is the Teacher. The Teacher is B. Correct Answer: B', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012a', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012a', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012a');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012b', 'dddddddd-dddd-dddd-dddd-000000000014', 'Four people—A, B, C, and D—each have a different profession: Doctor, Engineer, Pilot, or Actor. B is the Pilot. D is the Actor. A is not the Doctor. Who is the Doctor?', 'MCQ', 'MEDIUM', '{"options": ["A", "B", "C", "D", "Cannot be determined"]}', 'C', 'Step 1: We have four people (A, B, C, D) and four professions (Doctor, Engineer, Pilot, Actor). Step 2: B is the Pilot. (B = Pilot). Step 3: D is the Actor. (D = Actor). Step 4: The remaining people are A and C. The remaining professions are Doctor and Engineer. Step 5: We are told A is not the Doctor. Step 6: Therefore, A must be the Engineer. (A = Engineer). Step 7: The only remaining person is C, and the only remaining profession is Doctor. (C = Doctor). Correct Answer: C', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012b', 'eeeeeeee-eeee-eeee-eeee-000000000014', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012b', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012b');

-- Theme Detection -> topic Theme Detection
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000015', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Theme Detection', 'Involves identifying the central idea or underlying message that the author intends to convey in a given passage or statement.', 'MEDIUM', 27, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000015');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000015', 'dddddddd-dddd-dddd-dddd-000000000015', 'Theme Detection Challenge', 'Apply theme detection skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000015');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012c', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage carefully and determine the author''s underlying purpose and attitude. Passage: "While technological advancement has provided unprecedented convenience, it has simultaneously created new forms of dependency and vulnerability. Remote work, artificial intelligence, and digital banking offer efficiency, yet system failures can paralyze entire economies. Cybersecurity threats grow as our reliance on technology deepens. The question is not whether technology is good or bad, but whether we can develop social and institutional safeguards proportional to our technological capabilities."', 'MCQ', 'HARD', '{"options": ["To celebrate technological progress", "To critique both technological benefits and risks while advocating for balanced development with protective frameworks", "To prove that technology is inherently harmful", "To discourage technological adoption", "To explain how technology works"]}', 'To critique both technological benefits and risks while advocating for balanced development with protective frameworks', 'The author presents a balanced argument acknowledging both benefits ("unprecedented convenience") and risks ("dependency," "vulnerability").
Rather than advocating for either extreme, the author''s intent is to argue for a nuanced approach: continued technological development must be accompanied by proportional social and institutional protections.
This reflects a critical yet forward-thinking perspective that goes beyond simple acceptance or rejection.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012c', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012c', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012d', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and choose the option that most comprehensively summarizes the passage''s complete message and implications. Passage: "The Green Revolution of the 1960s dramatically increased crop yields through high-yielding seed varieties and chemical inputs, temporarily solving food security issues. However, decades of intensive monoculture farming depleted soil nutrients, reduced biodiversity, and increased dependency on expensive chemical inputs. Smaller farmers, unable to afford these inputs, were often displaced. Today, sustainable agriculture advocates argue that addressing food security requires moving beyond chemical-intensive methods toward regenerative practices that restore soil health, reduce dependency on external inputs, and support smaller farming communities while maintaining productivity."', 'MCQ', 'HARD', '{"options": ["The Green Revolution was completely successful", "Sustainable agriculture is expensive and impractical", "Chemical farming is inherently evil", "Traditional farming cannot produce sufficient food", "Agricultural sustainability requires balancing productivity with soil health and social equity through regenerative practices"]}', 'Agricultural sustainability requires balancing productivity with soil health and social equity through regenerative practices', 'The passage presents a historical perspective (Green Revolution''s impact), identifies long-term consequences (soil depletion, farmer displacement), and proposes solutions (regenerative practices).
The complete message encompasses this arc: initial success created unintended problems requiring new approaches that balance multiple factors.
Option B captures this comprehensive narrative, while others focus on single aspects or draw incorrect conclusions.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012d', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012d', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012e', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and identify the overarching main idea that provides cohesion to all presented information. Passage: "Privacy erosion through data collection has become normalized in the digital age. Every online transaction generates data that companies analyze and monetize. Facial recognition technology enables surveillance at unprecedented scale. Governments increasingly request user data from technology companies. Individuals often cannot comprehend the full extent of data collection affecting them. While data analysis offers benefits like personalized services and improved security, the asymmetrical power dynamic—where corporations and governments know far more about citizens than citizens know about them—creates significant risks to freedom and autonomy."', 'MCQ', 'HARD', '{"options": ["Technology companies are evil", "People should not use technology", "Privacy laws should ban all data collection", "Ubiquitous data collection and surveillance create power imbalances threatening individual freedom despite some practical benefits", "Data collection has no negative consequences"]}', 'Ubiquitous data collection and surveillance create power imbalances threatening individual freedom despite some practical benefits', 'The passage systematically presents multiple dimensions of data collection (corporate, governmental, technological), explains why it matters (power asymmetry), and acknowledges complexity (some benefits exist).
The main idea unifying all elements is that pervasive data collection creates troubling power imbalances threatening autonomy.
This connects all specific examples while acknowledging nuance—the central theme transcends simple "technology is bad" to address systemic power dynamics.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012e', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012e', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012f', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and extract the common underlying theme connecting seemingly disparate ideas. Passage: "Medieval physicians relied on humoral theory to treat diseases, often making patients worse. Phrenology claimed personality traits could be determined by skull shape, leading to racist classifications. During the 1950s, frontal lobotomies were performed as psychiatric treatment, causing permanent brain damage. Each generation of medical professionals believed their approaches were scientifically sound. Today''s treatments will likely be viewed as crude by future physicians. This historical pattern reveals something profound about scientific knowledge: it is provisional, evolving, and shaped by the intellectual frameworks available in each era."', 'MCQ', 'HARD', '{"options": ["Medical science has always been incorrect", "Scientific knowledge is provisional and evolves as intellectual frameworks advance, making current ''certainties'' subject to future revision", "All doctors are incompetent", "Modern medicine is no better than medieval practices", "Scientific progress is impossible"]}', 'Scientific knowledge is provisional and evolves as intellectual frameworks advance, making current ''certainties'' subject to future revision', 'The passage presents multiple historical medical failures but doesn''t aim to criticize those practitioners.
Instead, it uses these examples to extract a deeper theme about the nature of scientific knowledge itself.
The central thread connecting all examples is that scientific understanding at any point in time reflects available intellectual frameworks and is subject to revision.
This meta-theme about knowledge''s provisional nature transcends individual medical practices and represents the author''s fundamental message.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012f', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000012f', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000012f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000130', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and determine the author''s sophisticated purpose, considering both explicit and implicit messaging. Passage: "Wealth inequality has reached historical extremes, with the richest 1% owning more than the middle 60%. This inequality stems not from individual laziness or hard work differentials, but from structural systems: inheritance, compound returns on existing capital, network advantages, and systemic discrimination in lending and hiring. Yet political discourse frames poverty as a moral failing requiring individual responsibility narratives. This disconnect between structural causes and individualistic explanations perpetuates harmful stereotypes while obscuring policy solutions that could address root causes. Understanding poverty requires abandoning simplistic personal blame narratives in favor of systemic analysis."', 'MCQ', 'HARD', '{"options": ["To prove that wealthy people are bad", "To argue that poor people deserve their circumstances", "To expose how structural inequality causes poverty and critique misrepresenting it as individual failure, advocating for systemic rather than moral explanations", "To show that individual effort is irrelevant", "To prevent any economic discussion"]}', 'To expose how structural inequality causes poverty and critique misrepresenting it as individual failure, advocating for systemic rather than moral explanations', 'The author presents factual evidence of inequality, explicitly attributes it to structural causes, and critiques dominant narratives that misrepresent poverty.
The sophisticated intent involves multiple layers: (1) providing empirical foundation, (2) explaining systemic mechanisms, (3) analyzing discourse patterns, and (4) advocating for alternative frameworks.
Rather than simple criticism, the author aims to shift understanding from individualistic to structural perspectives—a nuanced purpose that requires readers to recognize how framing shapes perception and policy.
This reflects advocacy disguised as analysis.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000130');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000130', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000130', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000130');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000131', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and determine what common thread connects all the ideas presented. Passage: "Rising temperatures are melting polar ice caps. Coral reefs are bleaching due to warmer oceans. Wildlife habitats are shrinking as forests burn. Agricultural lands are becoming deserts."', 'MCQ', 'EASY', '{"options": ["Global warming causes various natural phenomena", "Different types of natural disasters", "How to protect endangered species", "The consequences of climate change on ecosystems", "The history of environmental degradation"]}', 'The consequences of climate change on ecosystems', 'All statements discuss different manifestations of climate change''s impact on nature.
Despite mentioning different aspects (ice caps, coral reefs, forests, agricultural lands), they all connect to a single central theme: climate change and its devastating environmental consequences.
The passage demonstrates how global warming affects multiple ecosystems.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000131');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000131', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000131', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000131');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000132', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage carefully and identify the central theme or main idea that best summarizes the entire passage. Passage: "The use of smartphones has revolutionized how we communicate and access information. However, excessive screen time has led to increased cases of eye strain, poor posture, and disrupted sleep patterns among teenagers."', 'MCQ', 'EASY', '{"options": ["The revolutionary features of smartphones", "The negative health effects of smartphone overuse", "The history of smartphone development", "How to use smartphones efficiently", "The benefits of mobile communication"]}', 'The negative health effects of smartphone overuse', 'The passage discusses both positive aspects (communication and information access) but predominantly focuses on the negative consequences (eye strain, poor posture, disrupted sleep).
The main idea centers on the harmful health effects of excessive smartphone use, particularly among teenagers.
The central theme is about balancing technological benefits with health concerns.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000132');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000132', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000132', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000132');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000133', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and identify the primary central idea. Passage: "Artificial intelligence is transforming industries from healthcare to manufacturing. AI algorithms can now diagnose diseases faster than human doctors. In factories, AI-powered robots increase productivity while reducing workplace injuries. The technology promises to revolutionize how we work and live."', 'MCQ', 'EASY', '{"options": ["Artificial intelligence replaces human workers", "Artificial intelligence has widespread transformative potential across multiple sectors", "Robots are better than doctors", "Technology always creates more problems than solutions", "Artificial intelligence is only used in healthcare"]}', 'Artificial intelligence has widespread transformative potential across multiple sectors', 'The passage emphasizes AI''s broad impact across different sectors (healthcare, manufacturing) and its transformative potential.
While it mentions specific applications, the main idea is that AI has revolutionary implications across multiple industries.
This central theme encompasses all the specific examples provided without limiting the scope to any single application.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000133');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000133', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000133', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000133');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000134', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage carefully and determine the underlying theme that connects all the statements. Passage: "Forests absorb carbon dioxide and produce oxygen. Wetlands filter pollutants from water. Coral reefs protect coastlines from erosion and support marine biodiversity. Mangrove forests prevent saltwater intrusion and provide breeding grounds for fish. Grasslands prevent soil erosion and support diverse animal populations."', 'MCQ', 'MEDIUM', '{"options": ["Different ecosystems exist in various parts of the world", "Environmental degradation is inevitable", "Natural ecosystems provide critical ecological services essential for environmental health", "Humans should stop interfering with nature", "Specific ecosystems are more important than others"]}', 'Natural ecosystems provide critical ecological services essential for environmental health', 'Each statement describes different ecosystems performing different functions, but the unifying central theme is that natural ecosystems provide vital ecological services.
The passage demonstrates ecosystem diversity while emphasizing the critical role each plays in maintaining environmental health.
This theme connects all statements and represents the author''s main message about ecosystem importance.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000134');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000134', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000134', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000134');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000135', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and identify what the author primarily intends to convey. Passage: "Many developing nations lack adequate infrastructure for waste management, leading to severe environmental pollution. Improper disposal of electronic waste contaminates groundwater and soil. In some regions, plastic waste accumulates in landfills for decades. These challenges threaten public health and ecosystem stability, yet few countries have implemented comprehensive solutions despite having the technology and knowledge to do so."', 'MCQ', 'MEDIUM', '{"options": ["To entertain readers with waste management statistics", "To highlight critical environmental challenges caused by inadequate waste management and urge action", "To prove that developing nations are inferior", "To suggest that waste management is impossible", "To explain different types of waste"]}', 'To highlight critical environmental challenges caused by inadequate waste management and urge action', 'The author presents a series of concerning problems (environmental pollution, water contamination, health threats) and emphasizes that solutions exist but aren''t implemented.
The critical tone combined with the lack of solutions despite available technology indicates the author''s intent is to highlight serious problems and implicitly urge governments and societies to take action.
This is persuasive and warning in nature.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000135');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000135', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000135', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000135');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000136', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and select the option that best summarizes the complete message. Passage: "Colonial education systems imposed foreign languages and curricula on colonized nations, erasing indigenous knowledge systems. Traditional oral histories, indigenous mathematics, and ecological wisdom were dismissed as inferior. Post-colonial societies continue struggling with this legacy, as educational frameworks emphasize Western perspectives over local contexts. Decolonizing education requires integrating indigenous knowledge with modern learning methodologies."', 'MCQ', 'MEDIUM', '{"options": ["Colonial powers were right to impose their educational systems", "Education should focus only on Western perspectives", "Indigenous knowledge is superior to Western education", "All countries should adopt identical educational systems", "Educational systems inherited from colonialism still impact post-colonial societies and decolonization requires integrating indigenous and modern knowledge"]}', 'Educational systems inherited from colonialism still impact post-colonial societies and decolonization requires integrating indigenous and modern knowledge', 'The passage traces education''s colonial legacy, explains its ongoing impact, and suggests solutions.
The central message encompasses all these elements: historical context, present consequences, and future direction.
Option B captures this comprehensive summary, while others either misinterpret or oversimplify the passage''s message.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000136');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000136', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000136', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000136');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000137', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and identify the author''s primary purpose or intent in writing it. Passage: "Physical exercise strengthens bones, improves cardiovascular health, and enhances mental well-being. Regular physical activity reduces the risk of chronic diseases like diabetes and heart disease. Even a 30-minute daily walk can significantly improve overall health outcomes."', 'MCQ', 'EASY', '{"options": ["To persuade readers to adopt regular physical exercise", "To criticize sedentary lifestyles", "To inform about different types of exercises", "To warn against excessive workouts", "To entertain with fitness facts"]}', 'To persuade readers to adopt regular physical exercise', 'The author presents multiple benefits of physical exercise and provides specific recommendations (30-minute daily walk).
The tone is encouraging and promotional.
The author''s intent is to persuade readers to incorporate regular physical activity into their daily lives for health benefits.
The passage uses evidence and practical suggestions to convince the audience.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000137');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000137', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000137', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000137');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000138', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and select the option that best captures the entire message in a single sentence. Passage: "Teachers play a crucial role in shaping students'' academic success, character development, and future careers. Quality teacher training ensures better classroom instruction. Schools that invest in teacher professional development produce students with stronger problem-solving skills and higher achievement levels."', 'MCQ', 'EASY', '{"options": ["Teachers should earn higher salaries than other professionals", "Improving education quality requires investment in teacher training and development", "Students should focus on character development more than academics", "Professional development is expensive for schools", "Teachers are responsible for all aspects of student life"]}', 'Improving education quality requires investment in teacher training and development', 'The passage integrates multiple ideas: the role of teachers, importance of training, and the outcomes of investment in teacher development.
The unifying theme is that enhancing teacher quality through training leads to better overall education outcomes.
Option B accurately summarizes the entire context while others focus on isolated details or incorrect interpretations.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000138');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000138', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000138', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000138');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000139', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and determine the primary central idea that governs the entire discussion. Passage: "Microplastics have been discovered in ocean water, drinking water, and the human bloodstream. These tiny plastic particles originate from the breakdown of larger plastic waste and microbeads in consumer products. Marine animals mistake microplastics for food, causing intestinal damage and bioaccumulation through the food chain. Scientists are alarmed that microplastics may pose unknown health risks to humans who consume contaminated seafood and water."', 'MCQ', 'MEDIUM', '{"options": ["Plastic products should be banned immediately", "Microplastic pollution represents a widespread environmental and health threat affecting ecosystems and potentially human health", "Ocean animals are becoming extinct", "Microplastics are beneficial for marine life", "Water is the primary source of microplastics"]}', 'Microplastic pollution represents a widespread environmental and health threat affecting ecosystems and potentially human health', 'The passage connects pollution (microplastics everywhere), source (plastic breakdown), ecological impact (marine damage, bioaccumulation), and human health concerns.
While each sentence presents specific information, they collectively support one main idea: microplastic contamination is a pervasive threat to both environmental and human health.
This central idea encompasses all discussed aspects.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000139');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000139', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000139', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000139');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013a', 'dddddddd-dddd-dddd-dddd-000000000015', 'Read the passage and identify the common thread that unites all the ideas. Passage: "Social media algorithms are designed to maximize user engagement regardless of content accuracy. Misinformation spreads faster than factual information on platforms like Twitter and Facebook. News outlets amplify sensational stories because they attract more readers. During elections, false narratives gain traction quickly through algorithmic amplification. Fact-checkers struggle to counter misinformation at the speed it spreads."', 'MCQ', 'MEDIUM', '{"options": ["Digital misinformation spreads rapidly due to algorithmic design and prioritization of engagement over accuracy", "Social media platforms are evil", "Traditional media is better than social media", "Fact-checkers are ineffective", "People should avoid using the internet"]}', 'Digital misinformation spreads rapidly due to algorithmic design and prioritization of engagement over accuracy', 'Each statement addresses different aspects of misinformation on digital platforms, but the unifying theme connects them: algorithmic systems designed to maximize engagement inadvertently (or deliberately) facilitate rapid misinformation spread.
This theme encompasses the platform mechanics, spread velocity, and challenges in countering false information—representing the core message about digital misinformation''s systemic nature.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013a');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013a', 'eeeeeeee-eeee-eeee-eeee-000000000015', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013a', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013a');

-- Verification of Truth of Statement -> topic Verification of Truth of Statement
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT 'dddddddd-dddd-dddd-dddd-000000000016', '55555555-5555-5555-5555-555555555501', '66666666-6666-6666-6666-666666666602', 'Verification of Truth of Statement', 'Involves analyzing given facts or information to determine whether a statement is definitely true, definitely false, or uncertain based on logical reasoning.', 'MEDIUM', 28, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = 'dddddddd-dddd-dddd-dddd-000000000016');

INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT 'eeeeeeee-eeee-eeee-eeee-000000000016', 'dddddddd-dddd-dddd-dddd-000000000016', 'Verification of Truth of Statement Challenge', 'Apply verification of truth of statement skills.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = 'eeeeeeee-eeee-eeee-eeee-000000000016');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013b', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read both statements and classify them appropriately. Statements: I. The Earth revolves around the Sun. II. Mathematics is more difficult than English.', 'MCQ', 'MEDIUM', '{"options": ["I is fact, II is opinion", "I is opinion, II is fact", "Both are facts", "Both are opinions", "Cannot classify"]}', 'I is fact, II is opinion', 'Statement I is a verifiable fact based on scientific evidence and astronomical observation—the Earth''s orbit around the Sun is a proven fact accepted universally by the scientific community.
Statement II reflects a personal or comparative judgment about relative difficulty.
Difficulty is subjective and varies significantly from person to person based on individual aptitude, learning style, and background.
Some students find mathematics more difficult while others find English more challenging.
Statement II expresses a belief or preference, not a universal truth.
Therefore, I is a fact and II is an opinion.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013b');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013b', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013b', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013b');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013c', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and identify contradictions. Statements: I. No politician is corrupt. II. Some corrupt individuals are politicians. III. All politicians are honest.', 'MCQ', 'MEDIUM', '{"options": ["No contradictions", "Statements I and II contradict", "All three statements contradict", "Statements I and III are consistent", "Cannot determine"]}', 'Statements I and II contradict', 'Statement I claims that no politician is corrupt, establishing zero corruption among all politicians universally.
Statement II claims that some corrupt individuals are politicians, asserting that at least one politician is corrupt.
These two statements directly contradict each other—they cannot both be true simultaneously.
If no politician is corrupt (Statement I), then no corrupt person can be a politician, which violates Statement II.
Statement III is a separate thematic claim that does not create a direct logical contradiction with the others in the same way.
The primary and clear contradiction exists between Statements I and II.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013c');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013c', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013c', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013c');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013d', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine whether the conclusion logically follows. Statements: I. All cats are animals. II. Some animals are pets. Conclusion: Some cats are pets.', 'MCQ', 'EASY', '{"options": ["TRUE", "FALSE", "Cannot be determined", "Partially true", "Insufficient data"]}', 'Cannot be determined', 'The first statement establishes that all cats are animals, creating a category relationship.
The second statement establishes that some animals are pets, but does not specify which animals.
While cats are animals, the information does not establish whether cats are among the animals that are pets.
Cats may or may not be pets based on the given information.
There is no direct link established between cats specifically and the pets category.
Therefore, the conclusion cannot be determined from the given statements alone.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013d');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013d', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013d', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013d');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013e', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statement and classify it as a fact or an opinion. Statement: "Online education is more effective than classroom learning."', 'MCQ', 'EASY', '{"options": ["Fact", "Opinion", "Partially fact", "Universal truth", "Verifiable claim"]}', 'Opinion', 'This statement reflects a personal judgment or belief rather than a verifiable fact.
While some individuals may prefer online education and others may prefer classroom learning, effectiveness depends on individual circumstances, learning styles, and context.
The statement uses a comparative value judgment ("more effective") which is subjective and varies by person.
Facts are statements that can be verified through objective evidence or observation, while this reflects personal belief and perspective.
Therefore, this is an opinion, not a fact.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013e');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013e', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013e', 4, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013e');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013f', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and evaluate their logical consistency. Statements: I. All mobile phones are electronic devices. II. Some electronic devices are not mobile phones. III. All mobile phones are technological innovations.', 'MCQ', 'MEDIUM', '{"options": ["Statements are consistent", "Statements I and II contradict", "Statements I and III contradict", "All statements contradict", "Cannot determine"]}', 'Statements are consistent', 'Statement I establishes that mobile phones form a subset of electronic devices (all mobile phones ⊆ electronic devices).
Statement II says some electronic devices exist outside the mobile phone category, which is perfectly consistent with Statement I.
Just because all mobile phones are electronic devices does not mean all electronic devices are mobile phones—other items like televisions and refrigerators are also electronic devices.
Statement III adds an additional property to mobile phones (being technological innovations), which does not contradict the other statements.
This is an independent attribute that coexists with their status as electronic devices.
All three statements can coexist logically without any contradiction.
Therefore, all statements are logically consistent.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013f');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013f', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-00000000013f', 5, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-00000000013f');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000140', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine if the conclusion follows logically. Statements: I. All teachers are knowledgeable. II. Some knowledgeable people are writers. Conclusion: Some teachers are writers.', 'MCQ', 'MEDIUM', '{"options": ["TRUE", "FALSE", "Cannot be determined", "Partially true", "Definitely false"]}', 'Cannot be determined', 'Statement I establishes that all teachers are knowledgeable, creating one categorical relationship.
Statement II establishes that some knowledgeable people are writers, but does not specify which knowledgeable people.
While teachers are knowledgeable, there is no guarantee that teachers are among the knowledgeable people who are writers.
Teachers might all be writers, some might be writers, or none might be writers—all scenarios remain logically possible.
The statements do not provide sufficient information to conclude definitively whether some teachers are writers.
There exists a logical gap between the premises and the conclusion.
Therefore, the truth of the conclusion cannot be determined from the given statements alone.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000140');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000140', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000140', 6, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000140');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000141', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine if they are logically consistent. Statements: I. All engineers are problem-solvers. II. Some problem-solvers are not engineers.', 'MCQ', 'EASY', '{"options": ["Consistent", "Inconsistent", "Partially consistent", "Cannot determine", "Neutral"]}', 'Consistent', 'Statement I establishes that all engineers are problem-solvers, creating a one-way relationship.
Statement II says some problem-solvers are not engineers, which means there are problem-solvers outside the engineer category.
This is perfectly consistent—just because all engineers are problem-solvers does not mean all problem-solvers must be engineers.
Many non-engineers can also be problem-solvers (teachers, doctors, artists, etc.).
There is no logical contradiction between these statements.
Therefore, they are logically consistent.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000141');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000141', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000141', 7, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000141');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000142', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and identify if a contradiction exists. Statements: I. All birds can fly. II. Penguins are birds and cannot fly.', 'MCQ', 'EASY', '{"options": ["No contradiction", "Contradiction exists", "Partial contradiction", "Cannot determine", "Insufficient information"]}', 'Contradiction exists', 'Statement I claims that all birds can fly, making flying a universal property of birds.
Statement II identifies penguins as birds that cannot fly, which directly contradicts the universal claim in Statement I.
If all birds can fly (as Statement I claims), then no bird can be non-flying, including penguins.
Since penguins are factually birds that cannot fly, Statements I and II cannot both be true simultaneously.
Therefore, a clear and direct contradiction exists between these statements.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000142');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000142', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000142', 8, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000142');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000143', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine which contradictions exist in this complex logical scenario. Statements: I. All sustainable businesses are profitable in the long term. II. Some businesses are sustainable but not profitable in the long term. III. Profitability in the long term requires sustainability. IV. Some profitable businesses are not sustainable.', 'MCQ', 'HARD', '{"options": ["Statements I and II contradict", "Statements III and IV contradict", "All statements contradict", "Statements I and III are consistent", "Statements I and II contradict; Statements III and IV contradict."]}', 'Statements I and II contradict; Statements III and IV contradict.', 'Statement I: All sustainable businesses are profitable (S → P)
Statement II: Some sustainable businesses are not profitable (∃S ¬P) → directly contradicts I
Statement III: Profitability requires sustainability (P → S)
Statement IV: Some profitable businesses are not sustainable (∃P ¬S) → directly contradicts III
Statements I and III: I (S → P) and III (P → S) together imply S ↔ P → consistent
Statements I and II contradict; Statements III and IV contradict.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000143');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000143', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000143', 9, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000143');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000144', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine whether the conclusion logically follows. Statements: I. All doctors are educated. II. Rajesh is a doctor. Conclusion: Rajesh is educated.', 'MCQ', 'EASY', '{"options": ["TRUE", "FALSE", "Cannot be determined", "Partially true", "Uncertain"]}', 'TRUE', 'Statement I establishes that all members of the "doctors" category possess the property "educated."
Statement II identifies Rajesh as a member of the "doctors" category.
Following logical deduction, if all members of a category share a property, and Rajesh is a member of that category, then Rajesh must have that property.
Therefore, Rajesh must be educated based on the premises given.
The conclusion logically and necessarily follows from the statements.
The statement is true.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000144');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000144', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000144', 10, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000144');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000145', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and identify all contradictions present. Statements: I. Every successful innovation requires significant investment. II. Some successful innovations developed with minimal resources. III. All minimal-resource projects succeed eventually.', 'MCQ', 'HARD', '{"options": ["No contradictions", "Statements I and II contradict", "Statements II and III contradict", "Statements I and III contradict", "Multiple contradictions exist"]}', 'Statements I and II contradict', 'Statement I claims that success in innovation universally requires significant investment, establishing a necessary condition.
Statement II provides examples of successful innovations that were developed with minimal resources, creating a direct contradiction.
If every successful innovation requires significant investment (Statement I), then no successful innovation can exist with minimal resources (contradicting Statement II).
Historical evidence shows innovations like Google (started in a garage) and many open-source projects succeeding with minimal initial investment, supporting Statement II.
Statement III is a separate claim about minimal-resource projects and doesn''t directly contradict the others in the same logical way.
The primary and clear contradiction exists between Statements I and II.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000145');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000145', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000145', 11, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000145');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000146', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and classify them, considering scientific and contextual nuance. Statements: I. Climate change is caused primarily by human activities. II. All humans should prioritize environmental conservation.', 'MCQ', 'HARD', '{"options": ["I is fact, II is opinion", "I is opinion, II is fact", "Both are facts", "Both are opinions", "Cannot be classified"]}', 'I is fact, II is opinion', 'Statement I is a fact supported by scientific consensus, peer-reviewed research, and data from major organizations like the IPCC (Intergovernmental Panel on Climate Change).
While scientists continue refining the mechanisms of climate change, the evidence-based consensus clearly demonstrates that human activities are the primary cause of modern climate change.
This is verifiable through observable data and scientific methodology.
Statement II, while morally and environmentally reasonable, is an opinion because "should prioritize" reflects a value judgment and prescriptive belief about what actions people ought to take.
Not all humans may agree on the priority level, methods, or implementation of environmental conservation.
Therefore, I is a fact and II is an opinion.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000146');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000146', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000146', 12, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000146');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000147', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read all statements and determine their overall logical consistency. Statements: I. All members of the research team are PhDs. II. Some PhDs are not published authors. III. All research team members have published papers. IV. Some published authors are not research team members.', 'MCQ', 'HARD', '{"options": ["All consistent", "Statements I and III are consistent", "Statements I and III contradict", "Statements II and III contradict", "Cannot determine"]}', 'Statements I and III contradict', 'Analyzing the relationships:
Statements I and III together establish that all research team members are published PhDs (they have both properties).
Statement II claims that some PhDs exist who are not published authors (acknowledging PhDs outside the published category).
If all research team members are published PhDs (from Statements I and III), and some PhDs are not published (Statement II), then the non-published PhDs must be outside the research team.
However, this creates a logical constraint: if Statement III says all team members published, but Statement II says some PhDs are not published, then any team member PhD must be published.
This means no team member can fall into the "PhD not published" category, which is consistent with Statement III but creates tension with the general claim in Statement II.
Statements I and III together contradict the implication that some team-member PhDs could be unpublished, as allowed by Statement II.
Therefore, Statements I and III contradict the logical implications of Statement II.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000147');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000147', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000147', 13, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000147');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000148', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine if they are logically consistent. Statements: I. All successful entrepreneurs take risks. II. Some risk-takers are not successful. III. Some successful people do not take risks.', 'MCQ', 'MEDIUM', '{"options": ["All statements are consistent", "Statements I and II contradict", "Statements II and III contradict", "Statements I and III contradict", "All three statements contradict"]}', 'Statements II and III contradict', 'Statement I establishes that success requires risk-taking (success → risk-taking).
Statement III claims that some successful people do not take risks, which directly contradicts Statement I.
If all successful entrepreneurs must take risks, then no successful person can avoid taking risks.
However, Statement II (some risk-takers are not successful) is consistent with Statement I because taking risks does not guarantee success.
The primary contradiction exists between Statements I and III, making the entire set logically inconsistent.
Not all three statements can be true simultaneously.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000148');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000148', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000148', 14, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000148');

INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT 'e0e0e0e0-e0e0-e0e0-e0e0-000000000149', 'dddddddd-dddd-dddd-dddd-000000000016', 'Read the statements and determine if the conclusion is valid based on logical inference. Statements: I. All renewable energy sources are sustainable. II. Some sustainable practices are expensive. III. Not all expensive practices are renewable energy sources. Conclusion: Some renewable energy sources are expensive.', 'MCQ', 'HARD', '{"options": ["TRUE", "FALSE", "Cannot be determined", "Partially true", "Definitely false"]}', 'Cannot be determined', 'Statement I establishes that renewable energy sources form a subset of sustainable practices (renewable ⊆ sustainable).
Statement II says some sustainable practices are expensive, but does not specify which sustainable practices are expensive.
Statement III provides additional information that not all expensive practices are renewable energy sources.
However, none of these statements directly establish a definitive link between renewable energy sources specifically and expensiveness.
While it is plausible that some renewable energy sources are expensive, the given information does not logically guarantee or necessitate this conclusion.
There exists a logical gap between the premises and conclusion—we cannot determine whether the expensive practices mentioned in Statement II include renewable energy sources.
Therefore, the conclusion cannot be determined from the given statements alone.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = 'e0e0e0e0-e0e0-e0e0-e0e0-000000000149');

INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT 'f0f0f0f0-f0f0-f0f0-f0f0-000000000149', 'eeeeeeee-eeee-eeee-eeee-000000000016', 'e0e0e0e0-e0e0-e0e0-e0e0-000000000149', 15, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = 'f0f0f0f0-f0f0-f0f0-f0f0-000000000149');
