# GameLearn AI --- Database Specification

**Project:** GameLearn AI --- A Smart Adaptive Learning Adventure\
**Problem Statement:** AIS-01\
**Category:** Adaptive Intelligence System\
**Domain:** Edutainment\
**Application:** Mobile Application\
**Backend:** Java + Spring Boot\
**Database:** MySQL\
**AI:** Gemini API\
**Status:** APPROVED BASELINE FOR PHASE 1\
**Version:** 1.0

------------------------------------------------------------------------

## 1. Purpose

This document is the database contract for GameLearn AI.

It converts the conceptual persistence model defined by the Backend + AI
architecture into a concrete MySQL design for Phase 1.

The database must support:

-   user identity and learner profiles
-   subjects and topics
-   lessons
-   learning paths
-   quizzes and questions
-   assessment/quiz attempts
-   topic mastery
-   learner progress
-   adaptive recommendations
-   XP and gamification
-   achievements
-   streaks
-   AI interaction metadata

The backend remains authoritative for all learner state.

Flutter must never access MySQL directly.

Gemini must never directly access MySQL.

------------------------------------------------------------------------

# 2. Architectural Principles

## 2.1 Backend authority

The following values are controlled by Spring Boot:

-   quiz scores
-   topic mastery
-   progress
-   recommendations
-   XP
-   level
-   achievements
-   streaks

The mobile client may request actions but must not directly write
authoritative learner state.

## 2.2 AI boundary

Never implement:

``` text
Gemini â†’ MySQL
```

Use:

``` text
Spring Boot
    â†“
AI Service
    â†“
Gemini
    â†“
Parse
    â†“
Schema Validation
    â†“
Business Validation
    â†“
Persistence
```

## 2.3 Adaptive boundary

The Adaptive Engine decides:

> What should the learner do next?

Gemini decides:

> What learning content should be generated?

Gemini must not replace the deterministic Adaptive Engine.

------------------------------------------------------------------------

# 3. ID Strategy

## Approved baseline

Use UUID identifiers for domain entities.

Application type:

``` text
java.util.UUID
```

MySQL representation:

``` text
CHAR(36)
```

Reason:

-   avoids predictable sequential public IDs
-   suitable for mobile/API systems
-   simple to debug during the hackathon
-   avoids collisions if the architecture expands later

Do not mix UUID and auto-increment IDs for ordinary domain entities
without an explicit architectural decision.

------------------------------------------------------------------------

# 4. Common Timestamp Convention

Use UTC consistently.

Common fields:

``` text
created_at TIMESTAMP NOT NULL
updated_at TIMESTAMP NOT NULL
```

Immutable history/event tables may omit `updated_at` where appropriate.

Application and database timezone behavior must remain consistent.

------------------------------------------------------------------------

# 5. Enum Convention

Persist enum values as strings.

Example:

``` text
EASY
MEDIUM
HARD
```

Never persist Java ordinal values.

------------------------------------------------------------------------

# 6. Entity Overview

The approved baseline contains:

``` text
users
learner_profiles
subjects
topics
lessons
learning_paths
learning_path_nodes
quizzes
questions
quiz_questions
quiz_attempts
question_attempts
topic_mastery
progress
recommendations
xp_transactions
achievements
user_achievements
streaks
ai_interactions
```

------------------------------------------------------------------------

# 7. users

Stores account identity and authentication-related user data.

  Column          Type           Null   Constraint
  --------------- -------------- ------ ----------------
  id              CHAR(36)       NO     PK
  email           VARCHAR(255)   NO     UNIQUE
  password_hash   VARCHAR(255)   NO
  display_name    VARCHAR(100)   NO
  status          VARCHAR(30)    NO     DEFAULT ACTIVE
  created_at      TIMESTAMP      NO
  updated_at      TIMESTAMP      NO

### Status values

``` text
ACTIVE
INACTIVE
SUSPENDED
```

Security:

-   plaintext passwords are forbidden
-   password hashes must never be returned by APIs
-   password hashes must never be logged

------------------------------------------------------------------------

# 8. learner_profiles

Stores the learner's current high-level state.

  Column               Type           Null   Constraint
  -------------------- -------------- ------ ---------------------
  id                   CHAR(36)       NO     PK
  user_id              CHAR(36)       NO     UNIQUE, FK users.id
  current_level        INT            NO     DEFAULT 1
  total_xp             INT            NO     DEFAULT 0
  overall_mastery      DECIMAL(5,2)   NO     DEFAULT 0
  current_subject_id   CHAR(36)       YES    FK subjects.id
  current_topic_id     CHAR(36)       YES    FK topics.id
  created_at           TIMESTAMP      NO
  updated_at           TIMESTAMP      NO

Rules:

-   one user has one learner profile
-   total XP is a current-state projection
-   XP history remains in `xp_transactions`
-   mastery details remain in `topic_mastery`

------------------------------------------------------------------------

# 9. subjects

Stores learning subjects.

  Column          Type           Null   Constraint
  --------------- -------------- ------ --------------
  id              CHAR(36)       NO     PK
  name            VARCHAR(100)   NO     UNIQUE
  description     TEXT           YES
  icon_key        VARCHAR(100)   YES
  is_active       BOOLEAN        NO     DEFAULT TRUE
  display_order   INT            NO     DEFAULT 0
  created_at      TIMESTAMP      NO
  updated_at      TIMESTAMP      NO

Initial seed subjects:

``` text
Programming
Computer Networks
DBMS
Operating Systems
Data Structures
```

The schema must support adding subjects without structural changes.

------------------------------------------------------------------------

# 10. topics

Stores topics belonging to subjects.

  Column          Type           Null   Constraint
  --------------- -------------- ------ ----------------
  id              CHAR(36)       NO     PK
  subject_id      CHAR(36)       NO     FK subjects.id
  name            VARCHAR(150)   NO
  description     TEXT           YES
  difficulty      VARCHAR(20)    NO
  display_order   INT            NO
  is_active       BOOLEAN        NO     DEFAULT TRUE
  created_at      TIMESTAMP      NO
  updated_at      TIMESTAMP      NO

Unique:

``` text
(subject_id, name)
```

Difficulty:

``` text
EASY
MEDIUM
HARD
```

------------------------------------------------------------------------

# 11. lessons

Stores approved lesson content.

  Column        Type           Null   Constraint
  ------------- -------------- ------ --------------
  id            CHAR(36)       NO     PK
  topic_id      CHAR(36)       NO     FK topics.id
  title         VARCHAR(200)   NO
  content       LONGTEXT       NO
  summary       TEXT           YES
  difficulty    VARCHAR(20)    NO
  source_type   VARCHAR(30)    NO
  is_active     BOOLEAN        NO     DEFAULT TRUE
  created_at    TIMESTAMP      NO
  updated_at    TIMESTAMP      NO

Source:

``` text
CURATED
AI_GENERATED
```

AI-generated content must be validated before persistence.

------------------------------------------------------------------------

# 12. learning_paths

Stores personalized learning paths.

  Column         Type           Null   Constraint
  -------------- -------------- ------ ----------------
  id             CHAR(36)       NO     PK
  user_id        CHAR(36)       NO     FK users.id
  subject_id     CHAR(36)       NO     FK subjects.id
  title          VARCHAR(200)   NO
  description    TEXT           YES
  status         VARCHAR(30)    NO
  generated_by   VARCHAR(30)    NO
  created_at     TIMESTAMP      NO
  updated_at     TIMESTAMP      NO

Status:

``` text
ACTIVE
COMPLETED
ARCHIVED
```

Generated by:

``` text
SYSTEM
AI
HYBRID
```

------------------------------------------------------------------------

# 13. learning_path_nodes

Stores ordered topics inside a learning path.

  Column             Type           Null   Constraint
  ------------------ -------------- ------ ----------------------
  id                 CHAR(36)       NO     PK
  learning_path_id   CHAR(36)       NO     FK learning_paths.id
  topic_id           CHAR(36)       NO     FK topics.id
  sequence_number    INT            NO
  required_mastery   DECIMAL(5,2)   YES
  status             VARCHAR(30)    NO
  created_at         TIMESTAMP      NO
  updated_at         TIMESTAMP      NO

Unique:

``` text
(learning_path_id, sequence_number)
```

Status:

``` text
LOCKED
AVAILABLE
IN_PROGRESS
COMPLETED
```

------------------------------------------------------------------------

# 14. quizzes

Stores quiz definitions.

  Column               Type           Null   Constraint
  -------------------- -------------- ------ --------------
  id                   CHAR(36)       NO     PK
  topic_id             CHAR(36)       NO     FK topics.id
  title                VARCHAR(200)   NO
  description          TEXT           YES
  difficulty           VARCHAR(20)    NO
  source_type          VARCHAR(30)    NO
  time_limit_seconds   INT            YES
  is_active            BOOLEAN        NO     DEFAULT TRUE
  created_at           TIMESTAMP      NO
  updated_at           TIMESTAMP      NO

Source:

``` text
CURATED
AI_GENERATED
```

------------------------------------------------------------------------

# 15. questions

Stores reusable questions.

  Column           Type           Null   Constraint
  ---------------- -------------- ------ --------------
  id               CHAR(36)       NO     PK
  topic_id         CHAR(36)       NO     FK topics.id
  question_text    TEXT           NO
  question_type    VARCHAR(30)    NO
  difficulty       VARCHAR(20)    NO
  options_json     JSON           YES
  correct_answer   VARCHAR(255)   NO
  explanation      TEXT           YES
  source_type      VARCHAR(30)    NO
  is_active        BOOLEAN        NO     DEFAULT TRUE
  created_at       TIMESTAMP      NO
  updated_at       TIMESTAMP      NO

Initial question type:

``` text
MCQ
```

AI-generated questions must pass structural and business validation
before insertion.

------------------------------------------------------------------------

# 16. quiz_questions

Associates questions with quizzes and preserves order.

  Column           Type        Null   Constraint
  ---------------- ----------- ------ -----------------
  id               CHAR(36)    NO     PK
  quiz_id          CHAR(36)    NO     FK quizzes.id
  question_id      CHAR(36)    NO     FK questions.id
  question_order   INT         NO
  created_at       TIMESTAMP   NO

Unique:

``` text
(quiz_id, question_id)
(quiz_id, question_order)
```

------------------------------------------------------------------------

# 17. quiz_attempts

Stores learner quiz attempts.

  Column                  Type           Null   Constraint
  ----------------------- -------------- ------ ---------------
  id                      CHAR(36)       NO     PK
  quiz_id                 CHAR(36)       NO     FK quizzes.id
  user_id                 CHAR(36)       NO     FK users.id
  score                   DECIMAL(5,2)   NO
  correct_count           INT            NO
  total_questions         INT            NO
  difficulty_at_attempt   VARCHAR(20)    NO
  started_at              TIMESTAMP      NO
  submitted_at            TIMESTAMP      YES
  duration_seconds        INT            YES
  status                  VARCHAR(30)    NO
  created_at              TIMESTAMP      NO
  updated_at              TIMESTAMP      NO

Status:

``` text
IN_PROGRESS
COMPLETED
ABANDONED
```

The backend calculates the authoritative score.

------------------------------------------------------------------------

# 18. question_attempts

Stores answer-level performance.

  Column                  Type           Null   Constraint
  ----------------------- -------------- ------ ---------------------
  id                      CHAR(36)       NO     PK
  quiz_attempt_id         CHAR(36)       NO     FK quiz_attempts.id
  question_id             CHAR(36)       NO     FK questions.id
  selected_answer         VARCHAR(255)   YES
  is_correct              BOOLEAN        NO
  response_time_seconds   INT            YES
  created_at              TIMESTAMP      NO

Recommended indexes:

``` text
quiz_attempt_id
question_id
```

This table is important for Adaptive Engine analysis.

------------------------------------------------------------------------

# 19. topic_mastery

Stores current mastery for each user/topic pair.

  Column               Type           Null   Constraint
  -------------------- -------------- ------ --------------
  id                   CHAR(36)       NO     PK
  user_id              CHAR(36)       NO     FK users.id
  topic_id             CHAR(36)       NO     FK topics.id
  mastery_score        DECIMAL(5,2)   NO     DEFAULT 0
  mastery_level        VARCHAR(30)    NO
  current_difficulty   VARCHAR(20)    NO
  attempt_count        INT            NO     DEFAULT 0
  recent_accuracy      DECIMAL(5,2)   NO     DEFAULT 0
  trend                VARCHAR(30)    NO
  last_assessed_at     TIMESTAMP      YES
  created_at           TIMESTAMP      NO
  updated_at           TIMESTAMP      NO

Unique:

``` text
(user_id, topic_id)
```

Mastery levels:

``` text
BEGINNER
DEVELOPING
PROFICIENT
MASTERED
```

Trend:

``` text
IMPROVING
STABLE
DECLINING
INSUFFICIENT_DATA
```

Important:

The database stores mastery state. The Adaptive Intelligence
Specification defines how mastery is calculated.

------------------------------------------------------------------------

# 20. progress

Stores learner progress.

  Column                  Type           Null   Constraint
  ----------------------- -------------- ------ ---------------------------
  id                      CHAR(36)       NO     PK
  user_id                 CHAR(36)       NO     FK users.id
  topic_id                CHAR(36)       NO     FK topics.id
  learning_path_node_id   CHAR(36)       YES    FK learning_path_nodes.id
  completion_percentage   DECIMAL(5,2)   NO     DEFAULT 0
  status                  VARCHAR(30)    NO
  last_activity_at        TIMESTAMP      YES
  completed_at            TIMESTAMP      YES
  created_at              TIMESTAMP      NO
  updated_at              TIMESTAMP      NO

Status:

``` text
NOT_STARTED
IN_PROGRESS
COMPLETED
```

------------------------------------------------------------------------

# 21. recommendations

Stores Adaptive Engine recommendations.

  Column                   Type          Null   Constraint
  ------------------------ ------------- ------ --------------
  id                       CHAR(36)      NO     PK
  user_id                  CHAR(36)      NO     FK users.id
  topic_id                 CHAR(36)      YES    FK topics.id
  activity_type            VARCHAR(40)   NO
  recommended_difficulty   VARCHAR(20)   YES
  reason                   TEXT          YES
  priority                 INT           NO     DEFAULT 0
  status                   VARCHAR(30)   NO
  generated_at             TIMESTAMP     NO
  consumed_at              TIMESTAMP     YES
  created_at               TIMESTAMP     NO
  updated_at               TIMESTAMP     NO

Activity types:

``` text
CONTINUE_LESSON
PRACTICE
REVIEW
QUIZ
REMEDIATION
ADVANCE
```

Status:

``` text
ACTIVE
CONSUMED
EXPIRED
```

The Adaptive Engine decides the recommendation.

------------------------------------------------------------------------

# 22. xp_transactions

Auditable XP history.

  Column           Type           Null   Constraint
  ---------------- -------------- ------ -------------
  id               CHAR(36)       NO     PK
  user_id          CHAR(36)       NO     FK users.id
  amount           INT            NO
  event_type       VARCHAR(50)    NO
  reference_type   VARCHAR(50)    YES
  reference_id     CHAR(36)       YES
  description      VARCHAR(255)   YES
  created_at       TIMESTAMP      NO

Event types:

``` text
LESSON_COMPLETED
QUIZ_COMPLETED
QUIZ_PERFORMANCE
ACHIEVEMENT_UNLOCKED
STREAK_BONUS
```

Exact XP values belong to the Gamification Specification.

------------------------------------------------------------------------

# 23. achievements

Defines available achievements.

  Column             Type           Null   Constraint
  ------------------ -------------- ------ --------------
  id                 CHAR(36)       NO     PK
  code               VARCHAR(80)    NO     UNIQUE
  name               VARCHAR(150)   NO
  description        TEXT           NO
  icon_key           VARCHAR(100)   YES
  rule_type          VARCHAR(50)    NO
  rule_config_json   JSON           YES
  xp_reward          INT            NO     DEFAULT 0
  is_active          BOOLEAN        NO     DEFAULT TRUE
  created_at         TIMESTAMP      NO
  updated_at         TIMESTAMP      NO

`rule_config_json` stores configuration data only; it must never contain
executable code.

------------------------------------------------------------------------

# 24. user_achievements

Stores unlocked achievements.

  Column           Type        Null   Constraint
  ---------------- ----------- ------ --------------------
  id               CHAR(36)    NO     PK
  user_id          CHAR(36)    NO     FK users.id
  achievement_id   CHAR(36)    NO     FK achievements.id
  unlocked_at      TIMESTAMP   NO
  created_at       TIMESTAMP   NO

Unique:

``` text
(user_id, achievement_id)
```

------------------------------------------------------------------------

# 25. streaks

Stores current streak state.

  Column                Type          Null   Constraint
  --------------------- ------------- ------ ---------------------
  id                    CHAR(36)      NO     PK
  user_id               CHAR(36)      NO     UNIQUE, FK users.id
  current_streak_days   INT           NO     DEFAULT 0
  longest_streak_days   INT           NO     DEFAULT 0
  last_learning_date    DATE          YES
  timezone              VARCHAR(64)   NO
  created_at            TIMESTAMP     NO
  updated_at            TIMESTAMP     NO

Exact streak/reset/recovery rules belong to the Gamification
Specification.

------------------------------------------------------------------------

# 26. ai_interactions

Stores AI interaction metadata and validated results where persistence
is required.

  Column                 Type           Null   Constraint
  ---------------------- -------------- ------ -------------
  id                     CHAR(36)       NO     PK
  user_id                CHAR(36)       NO     FK users.id
  interaction_type       VARCHAR(40)    NO
  model_name             VARCHAR(100)   YES
  prompt_version         VARCHAR(30)    YES
  request_context_json   JSON           YES
  response_json          JSON           YES
  status                 VARCHAR(30)    NO
  latency_ms             INT            YES
  error_code             VARCHAR(80)    YES
  created_at             TIMESTAMP      NO

Interaction types:

``` text
TUTOR
LEARNING_PATH
QUIZ_GENERATION
LESSON_GENERATION
HINT
RECOMMENDATION_SUPPORT
```

Status:

``` text
SUCCESS
FAILED
FALLBACK
REJECTED
```

Never store:

-   API keys
-   JWTs
-   passwords
-   system secrets

Private tutor conversations should only be persisted if required by the
approved product specification.

------------------------------------------------------------------------

# 27. Relationship Summary

``` text
User
 â”œâ”€â”€ 1:1 LearnerProfile
 â”œâ”€â”€ 1:N LearningPath
 â”œâ”€â”€ 1:N QuizAttempt
 â”œâ”€â”€ 1:N TopicMastery
 â”œâ”€â”€ 1:N Progress
 â”œâ”€â”€ 1:N Recommendation
 â”œâ”€â”€ 1:N XpTransaction
 â”œâ”€â”€ 1:N UserAchievement
 â”œâ”€â”€ 1:1 Streak
 â””â”€â”€ 1:N AiInteraction

Subject
 â”œâ”€â”€ 1:N Topic
 â””â”€â”€ 1:N LearningPath

Topic
 â”œâ”€â”€ 1:N Lesson
 â”œâ”€â”€ 1:N Quiz
 â”œâ”€â”€ 1:N Question
 â”œâ”€â”€ 1:N TopicMastery
 â”œâ”€â”€ 1:N Progress
 â””â”€â”€ 1:N Recommendation

LearningPath
 â””â”€â”€ 1:N LearningPathNode

Quiz
 â”œâ”€â”€ N:M Question through QuizQuestion
 â””â”€â”€ 1:N QuizAttempt

QuizAttempt
 â””â”€â”€ 1:N QuestionAttempt

Achievement
 â””â”€â”€ 1:N UserAchievement
```

------------------------------------------------------------------------

# 28. Cascade and Delete Policy

Do not use broad `CascadeType.ALL` or database `ON DELETE CASCADE`
without explicit justification.

Rules:

-   deleting a user must not delete global educational content
-   subjects/topics/lessons/quizzes are not user-owned content
-   learner history should be preserved where required
-   achievement definitions are global
-   XP transactions are audit history
-   account deletion/anonymization requires a separate approved policy

OpenCode must follow the approved relationships and avoid accidental
cascading.

------------------------------------------------------------------------

# 29. Index Strategy

Required/recommended indexes:

``` text
users(email)

topics(subject_id)

lessons(topic_id)

learning_paths(user_id, subject_id)

learning_path_nodes(learning_path_id, sequence_number)

quizzes(topic_id)

questions(topic_id)

quiz_questions(quiz_id, question_order)

quiz_attempts(user_id, quiz_id)

quiz_attempts(user_id, submitted_at)

question_attempts(quiz_attempt_id)

question_attempts(question_id)

topic_mastery(user_id, topic_id)

progress(user_id, topic_id)

recommendations(user_id, status)

xp_transactions(user_id, created_at)

user_achievements(user_id, achievement_id)

ai_interactions(user_id, created_at)
```

Do not create redundant indexes.

------------------------------------------------------------------------

# 30. Transaction Requirements

Quiz submission will eventually require an atomic service transaction:

``` text
Evaluate quiz
    â†“
Save QuizAttempt
    â†“
Save QuestionAttempts
    â†“
Update TopicMastery
    â†“
Update Progress
    â†“
Calculate XP
    â†“
Create XpTransaction
    â†“
Check Achievement
    â†“
Update Streak
    â†“
Create Recommendation
```

The database must support rollback if any critical operation fails.

The actual business transaction belongs to the service layer.

------------------------------------------------------------------------

# 31. Database Security

The implementation must ensure:

-   database credentials come from environment configuration
-   no credentials are committed
-   no plaintext passwords
-   no sensitive values in logs
-   JPA/parameterized queries are used
-   production database users follow least privilege
-   destructive startup schema recreation is forbidden
-   database credentials are never returned through APIs

------------------------------------------------------------------------

# 32. Migration Strategy

Flyway is the authoritative schema evolution mechanism.

Recommended logical migration organization:

``` text
V1__create_users_and_profiles.sql
V2__create_learning_content.sql
V3__create_learning_paths.sql
V4__create_quizzes_and_questions.sql
V5__create_attempts_and_progress.sql
V6__create_adaptive_tables.sql
V7__create_gamification_tables.sql
V8__create_ai_interactions.sql
```

These are organizational recommendations. OpenCode may split or combine
migrations where technically justified, but the final migration history
must be deterministic and clean.

Never use database recreation as normal application startup behavior.

------------------------------------------------------------------------

# 33. Seed Data

The initial subjects may be seeded:

``` text
Programming
Computer Networks
DBMS
Operating Systems
Data Structures
```

Seed data must be deterministic and repeatable.

Never seed real credentials.

------------------------------------------------------------------------

# 34. Adaptive Engine Data Contract

The database must provide enough data for future adaptive analysis:

-   overall accuracy
-   topic accuracy
-   recent performance
-   historical performance
-   attempt count
-   current difficulty
-   previous difficulty
-   correct/wrong patterns
-   mastery
-   progress
-   learning-path dependencies

The database does not contain the adaptive algorithm.

The Adaptive Intelligence Specification defines the algorithm.

------------------------------------------------------------------------

# 35. Gamification Data Contract

The database supports:

``` text
Learning Event
 â†“
XpTransaction
 â†“
Current XP
 â†“
Level
 â†“
Achievement
 â†“
Streak
```

The database stores state and history.

The Gamification Specification defines exact rules.

------------------------------------------------------------------------

# 36. API Boundary

The database supports future API areas:

``` text
AUTH
DASHBOARD
SUBJECTS
ASSESSMENT
LEARNING PATH
TOPICS
LESSONS
QUIZ
AI TUTOR
ACHIEVEMENTS
STREAK
PROGRESS
PROFILE
```

This document does not define endpoint paths or request/response DTOs.

Those belong to the API Contract.

------------------------------------------------------------------------

# 37. Entity-to-DTO Boundary

Never expose JPA entities directly through REST.

Use:

``` text
Entity
 â†“
Service
 â†“
DTO
 â†“
Controller
 â†“
Flutter
```

Sensitive fields such as `password_hash` must never reach API responses.

------------------------------------------------------------------------

# 38. Explicit Non-Goals

This document does not define:

-   JWT implementation
-   REST endpoint contracts
-   request/response JSON
-   mastery formula
-   difficulty algorithm
-   recommendation algorithm
-   XP values
-   level thresholds
-   streak recovery rules
-   Gemini prompts
-   AI output schemas
-   ML models
-   deployment infrastructure

These are separate specifications.

------------------------------------------------------------------------

# 39. Phase 1 Acceptance Criteria

Phase 1 implementation must translate this document into:

``` text
Database Specification
        â†“
Flyway Migrations
        â†“
MySQL Schema
        â†“
JPA Entities
        â†“
Repositories
        â†“
Integration Tests
```

OpenCode must verify:

-   clean database migration
-   migration repeatability
-   schema correctness
-   entity mapping
-   relationships
-   constraints
-   indexes
-   repository behavior
-   transaction rollback
-   security
-   Phase 0 regression

No authentication or business REST APIs are part of Phase 1.

------------------------------------------------------------------------

# 40. Approval Status

This document is now the approved baseline for Phase 1 implementation.

**APPROVED**

The next implementation step is to provide this document to OpenCode and
restart the Phase 1 prompt.

OpenCode must NOT invent schema details beyond this contract.

If an implementation conflict is discovered, OpenCode must stop and
report the conflict instead of silently changing the database contract.
