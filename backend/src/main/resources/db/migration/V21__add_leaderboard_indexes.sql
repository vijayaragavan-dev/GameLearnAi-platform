-- Leaderboard performance indexes (Phase L2)
-- Supports ORDER BY total_xp DESC, created_at ASC and subject XP derived queries.

CREATE INDEX idx_learner_profiles_total_xp ON learner_profiles (total_xp DESC);
CREATE INDEX idx_users_status_created ON users (status, created_at);
