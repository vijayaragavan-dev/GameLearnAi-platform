-- REALM-001: seed the Computer Science and Aptitude realms, then
-- associate every pre-existing subject with Computer Science.
-- No existing subject/topic/content row is modified other than the
-- realm_id backfill; all UUIDs and content stay exactly as seeded.

-- Computer Science realm (fixed stable UUID).
INSERT INTO realms (id, realm_key, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a01', 'COMPUTER_SCIENCE', 'Computer Science',
    'The complete Computer Science universe — programming, systems, data and AI worlds.',
    'realm_computer_science', TRUE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM realms WHERE realm_key = 'COMPUTER_SCIENCE');

-- Aptitude realm (fixed stable UUID). Active: it ships real curated
-- content in V31/V32. Verbal/FullStack/AI-Data/Cyber rows are NOT
-- seeded — they remain frontend-only honest placeholders.
INSERT INTO realms (id, realm_key, name, description, icon_key, is_active, display_order, created_at, updated_at)
SELECT '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a02', 'APTITUDE', 'Aptitude',
    'Quantitative aptitude and logical reasoning.',
    'realm_aptitude', TRUE, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM realms WHERE realm_key = 'APTITUDE');

-- Backfill: every subject created before the realm foundation belongs
-- to Computer Science. Idempotent (only touches NULL realm_id rows).
UPDATE subjects
SET realm_id = '0a0a0a0a-0a0a-0a0a-0a0a-0a0a0a0a0a01',
    updated_at = CURRENT_TIMESTAMP
WHERE realm_id IS NULL;
