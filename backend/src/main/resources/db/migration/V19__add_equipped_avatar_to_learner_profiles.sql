-- GameLearn AI - equipped avatar on learner profile (Phase L1)
-- Nullable FK to avatars. NULL means default Initiate visual
-- resolved in application code. Only owned avatars may be equipped
-- (enforced at service layer, not via DB trigger).

ALTER TABLE learner_profiles
    ADD COLUMN equipped_avatar_id CHAR(36) NULL;

ALTER TABLE learner_profiles
    ADD CONSTRAINT fk_learner_profiles__avatars
        FOREIGN KEY (equipped_avatar_id) REFERENCES avatars (id);

CREATE INDEX idx_learner_profiles_equipped_avatar ON learner_profiles (equipped_avatar_id);
