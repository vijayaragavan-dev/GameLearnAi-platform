-- GameLearn AI - Batch 1 / Phase 1: subject-world foundation (11 worlds).
-- Adds exactly 6 new canonical subjects; the 5 existing V11 subjects
-- (11111111-...-101..105) are preserved untouched.
--
-- Deterministic reserved UUID namespace (11111111-...-106..111) continuing
-- the V11 block, so the seed is repeatable and referentially stable.
-- Each row is INSERT...SELECT...WHERE NOT EXISTS (H2 + MySQL portable),
-- so re-running the statements never creates duplicates. Flyway additionally
-- guarantees each migration applies exactly once.
-- Additive only: no UPDATE, no DELETE, no schema change.

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111106', 'Object Oriented Programming', 'Java-centric object oriented programming: fundamentals, classes and objects, inheritance, polymorphism, exceptions, concurrency, collections, I/O and database connectivity.', 'subject_oop', TRUE, 6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111106');

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111107', 'Object Oriented Software Engineering', 'Software process, requirements, OOAD and UML, design principles and patterns, UML-to-code mapping, testing, refactoring and case studies.', 'subject_oose', TRUE, 7, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111107');

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111108', 'Web Technologies', 'Client and server web development: HTML5, CSS3, JavaScript and DOM, Servlets and sessions, PHP, XML technologies, AJAX and React.', 'subject_web_technologies', TRUE, 8, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111108');

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111109', 'Artificial Intelligence and Machine Learning', 'Problem solving and search, constraint satisfaction, Bayesian reasoning, supervised and unsupervised learning, ensembles, clustering and neural networks.', 'subject_ai_ml', TRUE, 9, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111109');

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111110', 'Foundations of Data Science', 'Data science process, exploratory analysis and statistics, NumPy and Pandas data manipulation, and Matplotlib/Seaborn visualization.', 'subject_data_science', TRUE, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111110');

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '11111111-1111-1111-1111-111111111111', 'Design and Analysis of Algorithms', 'Algorithm analysis and strategies: brute force, string matching, divide and conquer, dynamic programming, greedy methods, flow and matching, complexity classes, backtracking, branch and bound and approximation.', 'subject_algorithms', TRUE, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '11111111-1111-1111-1111-111111111111');
