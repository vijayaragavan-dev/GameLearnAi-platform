-- REALM-001: genuine Aptitude content seed (MVP set).
-- Aptitude subject + skill-grouping units + skill topics. All rows carry
-- fixed stable UUIDs and explicit realm association. Questions follow in
-- V32; game compatibility in V33.

-- Aptitude subject (belongs to the APTITUDE realm, NOT Computer Science).
INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, realm_id, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555501', 'Aptitude',
    'Quantitative aptitude and logical reasoning: arithmetic skills, number patterns, work problems and reasoning.',
    'aptitude', TRUE, 100, '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a02',
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM subjects WHERE id = '55555555-5555-5555-5555-555555555501');

-- Skill-grouping units (existing Unit model: Subject -> Unit -> Topic).
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555501',
    'Arithmetic', 'Core arithmetic skills: percentages, profit and loss, ratios.',
    1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '66666666-6666-6666-6666-666666666601');

INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555501',
    'Reasoning', 'Patterns, work problems and logical reasoning.',
    2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '66666666-6666-6666-6666-666666666602');

-- Skill topics (the Topic model naturally represents aptitude skills).
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777701', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666601', 'Percentages',
    'Percent calculations, increases, decreases and comparisons.', 'EASY', 1, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777701');

INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777702', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666601', 'Profit and Loss',
    'Cost price, selling price, profit percent and loss percent.', 'EASY', 2, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777702');

INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777703', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666601', 'Ratio and Proportion',
    'Ratios, proportions, mixtures and partnership sharing.', 'MEDIUM', 3, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777703');

INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777704', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666602', 'Number Series',
    'Arithmetic, geometric and mixed number patterns.', 'EASY', 4, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777704');

INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777705', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666602', 'Time and Work',
    'Work rates, combined work and time-distance basics.', 'MEDIUM', 5, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777705');

INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777706', '55555555-5555-5555-5555-555555555501',
    '66666666-6666-6666-6666-666666666602', 'Logical Reasoning',
    'Coding-decoding, blood relations and direction sense.', 'MEDIUM', 6, TRUE,
    CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '77777777-7777-7777-7777-777777777706');
