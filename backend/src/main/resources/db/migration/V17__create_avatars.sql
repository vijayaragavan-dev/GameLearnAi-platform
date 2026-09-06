-- GameLearn AI - avatar catalog (Phase L1)
-- Original GameLearnAI IP characters for the gamification store.
-- Stores display metadata and unlock requirement JSON. Rarity and cost
-- constraints are enforced here; ownership lives in user_avatars.

CREATE TABLE avatars (
    id               CHAR(36)      NOT NULL,
    code             VARCHAR(80)   NOT NULL,
    display_name     VARCHAR(100)  NOT NULL,
    description      VARCHAR(200)  NULL,
    rarity           VARCHAR(30)   NOT NULL,
    home_subject_id  CHAR(36)      NULL,
    asset_key        VARCHAR(120)  NOT NULL,
    requirement_json JSON          NULL,
    credit_cost      INT           NULL,
    is_active        BOOLEAN       NOT NULL DEFAULT TRUE,
    display_order    INT           NOT NULL DEFAULT 0,
    created_at       TIMESTAMP     NOT NULL,
    updated_at       TIMESTAMP     NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uq_avatars_code UNIQUE (code),
    CONSTRAINT fk_avatars__subjects FOREIGN KEY (home_subject_id) REFERENCES subjects (id),
    CONSTRAINT chk_avatars_rarity CHECK (rarity IN ('INITIATE','COMMON','RARE','EPIC','LEGENDARY','PRESTIGE')),
    CONSTRAINT chk_avatars_credit_cost CHECK (credit_cost IS NULL OR credit_cost > 0)
);

CREATE INDEX idx_avatars_rarity ON avatars (rarity, display_order);
CREATE INDEX idx_avatars_subject ON avatars (home_subject_id);
CREATE INDEX idx_avatars_active ON avatars (is_active);
