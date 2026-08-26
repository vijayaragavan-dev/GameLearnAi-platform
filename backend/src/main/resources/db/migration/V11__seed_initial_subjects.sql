-- GameLearn AI - initial subject seed data
-- (Database Specification section 33)
--
-- Deterministic, reserved UUID namespace (11111111-...-01..05) so the seed
-- is repeatable and referentially stable. No credentials are seeded.

INSERT INTO subjects (id, name, description, icon_key, is_active, display_order, created_at, updated_at) VALUES
    ('11111111-1111-1111-1111-111111111101', 'Programming', NULL, 'subject_programming', TRUE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('11111111-1111-1111-1111-111111111102', 'Computer Networks', NULL, 'subject_networks', TRUE, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('11111111-1111-1111-1111-111111111103', 'DBMS', NULL, 'subject_dbms', TRUE, 3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('11111111-1111-1111-1111-111111111104', 'Operating Systems', NULL, 'subject_operating_systems', TRUE, 4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    ('11111111-1111-1111-1111-111111111105', 'Data Structures', NULL, 'subject_data_structures', TRUE, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
