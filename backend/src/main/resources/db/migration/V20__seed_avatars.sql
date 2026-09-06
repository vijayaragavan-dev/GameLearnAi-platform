-- GameLearn AI - original avatar catalog seed (Phase L1)
-- 24 original GameLearnAI IP characters. No copyrighted IP.
-- Rarity gate: INITIATE auto-granted, COMMON/RARE purchasable with Credits,
-- EPIC/LEGENDARY threshold-claim (70% syllabus etc). Asset keys are first-party
-- vector identifiers; no binary assets in this phase.

-- Helper: all ids are deterministic UUIDs in reserved 2222 namespace.

-- INITIATE (2) — granted at onboarding
INSERT INTO avatars (id, code, display_name, description, rarity, home_subject_id, asset_key, requirement_json, credit_cost, is_active, display_order, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222001', 'initiates_spark', 'Nova Spark', 'Curious and bright — your first companion.', 'INITIATE', NULL, 'characters/nova_spark', NULL, NULL, TRUE, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222002', 'initiates_scout', 'Byte Scout', 'Trail-ready explorer of new worlds.', 'INITIATE', NULL, 'characters/byte_scout', NULL, NULL, TRUE, 2, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- COMMON (7) — low-cost cosmetic progression, requires level >= 2
INSERT INTO avatars (id, code, display_name, description, rarity, home_subject_id, asset_key, requirement_json, credit_cost, is_active, display_order, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222011', 'common_lumen_coder', 'Lumen Coder', 'Types fast, learns faster.', 'COMMON', NULL, 'characters/lumen_coder', '{"levelMin":2}', 1200, TRUE, 10, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222012', 'common_logic_leaf', 'Logic Leaf', 'Gentle logic, steady growth.', 'COMMON', NULL, 'characters/logic_leaf', '{"levelMin":2}', 900, TRUE, 11, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222013', 'common_pixel_pilot', 'Pixel Pilot', 'Navigates the learning sky.', 'COMMON', NULL, 'characters/pixel_pilot', '{"levelMin":2}', 1000, TRUE, 12, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222014', 'common_syntax_scout', 'Syntax Scout', 'Always finds the clear path.', 'COMMON', NULL, 'characters/syntax_scout', '{"levelMin":2}', 800, TRUE, 13, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222015', 'common_bit_bloom', 'Bit Bloom', 'Ideas blossom into code.', 'COMMON', NULL, 'characters/bit_bloom', '{"levelMin":2}', 1100, TRUE, 14, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222016', 'common_query_quill', 'Query Quill', 'Writes tidy questions.', 'COMMON', NULL, 'characters/query_quill', '{"levelMin":2}', 1300, TRUE, 15, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222017', 'common_loop_lynx', 'Loop Lynx', 'Iterates until perfect.', 'COMMON', NULL, 'characters/loop_lynx', '{"levelMin":2}', 1400, TRUE, 16, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- RARE (6) — moderate progression, requires level >= 6
INSERT INTO avatars (id, code, display_name, description, rarity, home_subject_id, asset_key, requirement_json, credit_cost, is_active, display_order, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222021', 'rare_net_ranger', 'Net Ranger', 'Patrols the OSI layers.', 'RARE', '11111111-1111-1111-1111-111111111102', 'characters/net_ranger', '{"levelMin":6}', 2500, TRUE, 20, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222022', 'rare_os_orbit', 'Orbit Keeper', 'Keeps operating systems in orbit.', 'RARE', '11111111-1111-1111-1111-111111111104', 'characters/orbit_keeper', '{"levelMin":6}', 2800, TRUE, 21, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222023', 'rare_structure_sentinel', 'Structure Sentinel', 'Guards data structures.', 'RARE', '11111111-1111-1111-1111-111111111105', 'characters/structure_sentinel', '{"levelMin":6}', 3000, TRUE, 22, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222024', 'rare_data_weaver', 'Data Weaver', 'Weaves queries into insight.', 'RARE', '11111111-1111-1111-1111-111111111103', 'characters/data_weaver', '{"levelMin":6}', 3200, TRUE, 23, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222025', 'rare_code_captain', 'Code Captain', 'Leads the programming voyage.', 'RARE', '11111111-1111-1111-1111-111111111101', 'characters/code_captain', '{"levelMin":6}', 3500, TRUE, 24, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222026', 'rare_signal_sage', 'Signal Sage', 'Reads every signal clearly.', 'RARE', '11111111-1111-1111-1111-111111111102', 'characters/signal_sage', '{"levelMin":6}', 4000, TRUE, 25, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- EPIC (5) — threshold claim, level >= 12, 50% syllabus, streak 7, home subject
INSERT INTO avatars (id, code, display_name, description, rarity, home_subject_id, asset_key, requirement_json, credit_cost, is_active, display_order, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222031', 'epic_algo_sage', 'Algo Sage', 'Sees patterns before they form.', 'EPIC', '11111111-1111-1111-1111-111111111105', 'characters/algo_sage', '{"levelMin":12,"syllabusCompletionMin":50.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111105","streakCurrentMin":7}', NULL, TRUE, 30, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222032', 'epic_network_nexus', 'Network Nexus', 'Connects every node.', 'EPIC', '11111111-1111-1111-1111-111111111102', 'characters/network_nexus', '{"levelMin":12,"syllabusCompletionMin":50.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111102","streakCurrentMin":7}', NULL, TRUE, 31, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222033', 'epic_os_titan', 'OS Titan', 'Masters the kernel realm.', 'EPIC', '11111111-1111-1111-1111-111111111104', 'characters/os_titan', '{"levelMin":12,"syllabusCompletionMin":50.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111104","streakCurrentMin":7}', NULL, TRUE, 32, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222034', 'epic_program_archon', 'Program Archon', 'Architect of code worlds.', 'EPIC', '11111111-1111-1111-1111-111111111101', 'characters/program_archon', '{"levelMin":12,"syllabusCompletionMin":50.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111101","streakCurrentMin":7}', NULL, TRUE, 33, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222035', 'epic_query_prime', 'Query Prime', 'Commands data with clarity.', 'EPIC', '11111111-1111-1111-1111-111111111103', 'characters/query_prime', '{"levelMin":12,"syllabusCompletionMin":50.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111103","streakCurrentMin":7}', NULL, TRUE, 34, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- LEGENDARY (4) — threshold claim, level >= 18, 70% syllabus, boss battles 5, streak 7, mastered 2
INSERT INTO avatars (id, code, display_name, description, rarity, home_subject_id, asset_key, requirement_json, credit_cost, is_active, display_order, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222041', 'legendary_db_oracle', 'Oracle of Data', 'Demands 70% mastery of data realms.', 'LEGENDARY', '11111111-1111-1111-1111-111111111103', 'characters/oracle_of_data', '{"levelMin":18,"syllabusCompletionMin":70.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111103","bossBattlesMin":5,"streakCurrentMin":7,"masteredCountMin":2}', NULL, TRUE, 40, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222042', 'legendary_code_sovereign', 'Code Sovereign', 'Sovereign of programming mastery.', 'LEGENDARY', '11111111-1111-1111-1111-111111111101', 'characters/code_sovereign', '{"levelMin":18,"syllabusCompletionMin":70.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111101","bossBattlesMin":5,"streakCurrentMin":7,"masteredCountMin":2}', NULL, TRUE, 41, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222043', 'legendary_network_warden', 'Network Warden', 'Warden of connected mastery.', 'LEGENDARY', '11111111-1111-1111-1111-111111111102', 'characters/network_warden', '{"levelMin":18,"syllabusCompletionMin":70.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111102","bossBattlesMin":5,"streakCurrentMin":7,"masteredCountMin":2}', NULL, TRUE, 42, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222044', 'legendary_kernel_legend', 'Kernel Legend', 'Legend of the deep kernel.', 'LEGENDARY', '11111111-1111-1111-1111-111111111104', 'characters/kernel_legend', '{"levelMin":18,"syllabusCompletionMin":70.0,"syllabusSubjectId":"11111111-1111-1111-1111-111111111104","bossBattlesMin":5,"streakCurrentMin":7,"masteredCountMin":2}', NULL, TRUE, 43, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
