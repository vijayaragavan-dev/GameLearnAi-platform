# GameLearn AI — Frontend UI/UX & Implementation Specification

**A Smart Adaptive Learning Adventure**
Problem Statement: AIS-01 | Category: Adaptive Intelligence System | Domain: Edutainment
Target: Flutter Mobile Application | Audience: Member 1 (Frontend Developer)

---

## 1. Document Purpose

This document is the frontend developer's **single source of truth** for building the GameLearn AI Flutter application. It defines what to build, how it must behave, what data it needs, which API it calls, what response it expects, and what happens after that response — so Member 1 can build independently without guessing.

This is not a visual design document. It is a **UI/UX + Functional + API Integration + Implementation Specification**.

---

## 2. Project Context

| Item | Value |
|---|---|
| Project | GameLearn AI: A Smart Adaptive Learning Adventure |
| Problem Statement | AIS-01 |
| Category | Adaptive Intelligence System |
| Domain | Edutainment |
| App Type | Mobile Application (Flutter) |
| Target Users | College students / technical learners |
| Core Subject Catalog | A curated, extensible catalog of core Computer Science and technical-learning subjects |
| Initial Core Areas | C, C++, Python, Java, OOP, Data Structures, DBMS, Operating Systems, Computer Networks, TOC, AI/ML, Web Technologies, Cyber Security, Cryptography, Aptitude and related core technical subjects |
| Subject Discovery | Curated core subjects are directly discoverable from the Dashboard; non-core/long-tail subjects are discoverable through AI-powered search |
| Extensibility | New subjects must be addable without frontend redesign |
| Learning Goal | A learner should be able to learn a selected core subject systematically through assessment, lessons, challenges, adaptive practice, AI assistance and progression |

**Core Concept — Closed-Loop Adaptive Learning:**

```
Student → Assessment → Learner Profile → Personalized Learning Path
   → Learning Activity → Challenge → Performance Analysis
   → Adaptive Decision → Personalized Next Activity
   → Gamification/Feedback → Updated Learner Profile → (repeat)
```

The frontend's job is to make this loop **visible and understandable** to the learner — not to run it.

---

## 3. Frontend Responsibilities

**The frontend IS responsible for:**
User interaction, screen rendering, navigation, form handling, client-side validation, API communication, auth state, displaying learner/AI-generated data, quiz interaction, learning-path/progress/gamification visualization, AI tutor UI, loading/error/empty states, network failure handling, session handling.

**The frontend must NOT:**
- Connect directly to MySQL
- Store or call the Gemini API directly
- Implement backend business logic
- Make final adaptive-learning decisions
- Calculate authoritative XP
- Modify database data directly

---

## 4. System Architecture Context

```
Flutter (Presentation Layer)
        ↓
Spring Boot REST API (Business Logic Layer)
        ↓
Backend / Adaptive Intelligence / AI Orchestration
        ↓
MySQL / Gemini API / Other Services
```

The frontend is a pure presentation and interaction layer. All authoritative decisions (adaptive difficulty, XP, learner profile, AI content) happen server-side.

**Document Hierarchy** — this spec sits alongside, and must never contradict, the Master Specification, API Contract, Database Spec, AI Specification, and Adaptive Learning Specification. Any conflict is flagged inline as:

> **CONTRACT CONFLICT — REQUIRES RESOLUTION**

---

## 5. Technology Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter + Dart |
| Architecture | Feature-based folder structure |
| State Management | [TBD — REQUIRES DECISION, see §13] |
| Networking | HTTP client with centralized API service layer |
| Local Storage | Secure storage for tokens; no sensitive data cached |
| Backend | Spring Boot REST API |
| Database | MySQL (backend-only access) |
| AI | Gemini API (backend-only access) |

Every dependency added must have a clear, justified purpose — no unnecessary packages.

---

## 6. Design Principles

- **Visibility of adaptation** — the learner should always understand *why* they're seeing a given activity.
- **Backend authority** — frontend renders; it never computes XP, difficulty, or next-topic decisions.
- **Consistency** — one design system, one error-handling pattern, one navigation pattern.
- **Contract fidelity** — never invent fields or endpoints; mark unknowns as `[TBD]`.
- **Adventure framing** — visual identity should communicate "Learning Adventure + Intelligent Technology," not a generic quiz app.

---

## 7. Application Information Architecture

```
Splash
  ↓
Onboarding
  ↓
Authentication ── Login / Register
  ↓
Dashboard
  ├── Subjects ── Assessment ── Learning Path ── Lessons ── Challenges ── Result ── Adaptation ── Next Recommendation
  ├── AI Tutor
  ├── Achievements
  ├── Progress
  ├── Profile
  └── Settings
```

---

## 8. Navigation Architecture

- **Splash → Onboarding** (first launch only) **→ Login/Register → Dashboard**
- **Dashboard** is the hub; bottom navigation (or equivalent) exposes: Dashboard, Learning Path, AI Tutor, Progress, Profile.
- **Learning flow** is linear and backend-driven: Subject → Assessment → Path → Lesson → Quiz → Result → Adaptation → back to Path/Dashboard.
- **Session expiry** at any point routes to Login and clears local auth state.

---

## 9. Screen Inventory

| # | Screen | Category |
|---|---|---|
| 1 | Splash | Auth |
| 2 | Onboarding | Auth |
| 3 | Login | Auth |
| 4 | Registration | Auth |
| 5 | Dashboard | Core |
| 6 | Subject Selection | Core |
| 7 | Assessment Introduction | Assessment |
| 8 | Assessment Question | Assessment |
| 9 | Assessment Result | Assessment |
| 10 | Personalized Learning Path | Learning |
| 11 | Topic Detail | Learning |
| 12 | Lesson | Learning |
| 13 | Challenge / Quiz | Challenge |
| 14 | Quiz Result | Challenge |
| 15 | Next Recommendation | Challenge |
| 16 | AI Tutor | AI |
| 17 | AI Explanation/Hint | AI |
| 18 | Achievements | Gamification |
| 19 | Badge Detail | Gamification |
| 20 | Streak/Progress Widget | Gamification |
| 21 | Progress Dashboard | Analytics |
| 22 | Topic Performance | Analytics |
| 23 | Profile | User |
| 24 | Settings | User |

---

## 10. Screen-by-Screen Specifications

> **Template used for every screen below:** Screen ID · Purpose · Entry/Exit · UI Components · User Actions · Validation · API Dependency · Request/Response · Success/Error Behavior · Loading/Empty/Offline State · Navigation · Accessibility · Analytics · Test Cases.
> All API IDs below are placeholders pending the API Contract document — treat every one as `[TBD — API CONTRACT REQUIRED]` until confirmed against that document.

### SCREEN-AUTH-001 — Splash
- **Purpose:** Brand entry point; checks stored auth token to decide routing.
- **Entry:** App launch. **Exit:** Onboarding (first launch) or Login or Dashboard (valid session).
- **Components:** Logo, loading indicator.
- **Actions:** None (auto-navigates after token check).
- **API Dependency:** `AUTH-000 [TBD]` — validate/refresh stored token.
- **Success:** Route to Dashboard. **Error/No token:** Route to Login.
- **Loading:** Full-screen branded loader, max ~2s before fallback to Login.
- **Accessibility:** Screen-reader announces app name on load.
- **Test cases:** Valid token → Dashboard; expired token → Login; no token → Login/Onboarding.

### SCREEN-AUTH-002 — Onboarding
- **Purpose:** Introduce the adaptive-learning concept to first-time users.
- **Entry:** Splash (first launch). **Exit:** Register/Login.
- **Components:** Swipeable illustration cards, skip button, "Get Started" CTA.
- **Actions:** Swipe, skip, proceed.
- **API Dependency:** None (static content).
- **Navigation:** → Login/Register.
- **Test cases:** Skip works from any slide; last slide shows CTA not "next."

### SCREEN-AUTH-003 — Login
- **Purpose:** Authenticate returning users.
- **Entry:** Onboarding/Splash/Logout. **Exit:** Dashboard, Register, Forgot Password.
- **Components:** Logo, email field, password field, login button, forgot password link, register link, loading indicator, error message.
- **Actions:** Enter credentials, submit, navigate to register/forgot password.
- **Validation:** Email format required; password non-empty; inline error on blur.
- **API Dependency:** `AUTH-001 [TBD]` — `POST /api/v1/auth/login`.
- **Request:** `{ email, password }`
- **Response:** `{ accessToken, user }` — exact shape per API Contract.
- **Success:** Store token securely → Dashboard.
- **Error Behavior:** 400/422 → inline validation message; 401 → "Invalid email or password"; 429 → "Too many attempts, try again later"; 500/timeout/network → generic retry banner.
- **Loading:** Button shows spinner, disabled during request.
- **Navigation:** Success → Dashboard; "Register" → Registration; "Forgot password" → `[TBD — FLOW NOT IN MASTER SPEC]`.
- **Accessibility:** Labeled fields, min 44x44 touch targets, error text linked to field via semantics.
- **Analytics:** `login_attempt`, `login_success`, `login_failure`.

### SCREEN-AUTH-004 — Registration
- **Purpose:** Create a new learner account.
- **Entry:** Login/Onboarding. **Exit:** Dashboard or back to Login.
- **Components:** Name, email, password, confirm password fields, register button, login link.
- **Validation:** All fields required; email format; password minimum length per contract; password match check.
- **API Dependency:** `AUTH-002 [TBD]` — `POST /api/v1/auth/register`.
- **Request:** `{ name, email, password }`
- **Response:** `{ accessToken, user }`
- **Error Behavior:** 409 → "Email already registered"; 422 → field-level validation errors; 500/network → retry banner.
- **Navigation:** Success → Dashboard (auto-login) or Login, per contract decision `[TBD]`.

### SCREEN-CORE-001 — Dashboard
- **Purpose:** Communicate learner's current state and answer "what should I do next?"
- **Entry:** Post-login, bottom nav. **Exit:** Subjects, Learning Path, AI Tutor, Progress, Profile.
- **Components:** Greeting, level, XP bar, streak indicator, current subject, learning progress, current/next topic, recommended challenge card, recent achievement, "Continue Learning" CTA.
- **API Dependency:** `DASH-001 [TBD]` — `GET /api/v1/dashboard`.
- **Response fields (indicative):** `{ user, level, xp, xpToNextLevel, streak, currentSubject, nextTopic, recommendedChallenge, recentAchievement }`
- **Rule:** The "next recommendation" shown is **exactly** what the backend returns — frontend never computes it.
- **Loading:** Skeleton cards for each dashboard section.
- **Empty State:** New user with no subject selected → "Choose a subject to begin your adventure" → Subject Selection.
- **Error:** "We couldn't load your dashboard" + retry.
- **Navigation:** "Continue Learning" → Learning Path or Lesson (backend-determined); Achievement tap → Badge Detail.

### SCREEN-CORE-002 — Subject Selection / Core Subject Hub
- **Purpose:** Let the learner discover and choose from the curated Core CS Subject Catalog.
- **Important Product Rule:** The Dashboard must not be limited to only five subjects. The product is intended to cover a broad, curated set of core Computer Science and technical-learning areas such as C, C++, Python, Java, OOP, Data Structures, DBMS, Operating Systems, Computer Networks, TOC, AI/ML, Web Technologies, Cyber Security, Cryptography, Aptitude and future approved core areas.
- **Components:** Search field, subject categories, subject cards, progress, mastery, current level, recommended badge, locked/available state where supplied by backend.
- **API Dependency:** `SUBJ-001 [TBD]` — `GET /api/v1/subjects`.
- **Response:** Exact subject contract only. Do not invent fields.
- **Rule:** The curated catalog is backend-driven and extensible. Flutter must not hard-code the authoritative subject list.
- **Search Rule:** Searching within the curated catalog must use backend-supported subject data. Do not create a second client-side subject database.
- **Navigation:** Select a subject → Assessment Introduction for a new subject, or Learning Path for an existing learner state.
- **Empty State:** "No matching core subjects found."
- **Important:** Subject selection is an entry point into an adaptive learning world, not the learning experience itself.

### SCREEN-ASMT-001 — Assessment Introduction
- **Purpose:** Explain the baseline assessment purpose and flow.
- **Components:** Instructions, question count, estimated time, "Start Assessment" CTA.
- **API Dependency:** `ASMT-001 [TBD]` — `GET /api/v1/assessment/{subjectId}`.
- **Navigation:** Start → Assessment Question.

### SCREEN-ASMT-002 — Assessment Question
- **Purpose:** Collect baseline answers; frontend does not grade.
- **Components:** Question text, progress indicator (e.g., "Q3 of N"), options, selection state, previous/next, submit (final question), confirmation dialog on submit.
- **Actions:** Select option, navigate question, submit.
- **Validation:** All required questions answered before submit (per contract rules).
- **API Dependency:** `ASMT-002 [TBD]` — `POST /api/v1/assessment/{subjectId}/submit`.
- **Request:** `{ answers: [{ questionId, selectedOptionId }] }`
- **Response:** Assessment result payload (see next screen).
- **Loading:** Full-screen submitting indicator on final submit.
- **Rule:** Frontend collects answers only; it is never the authoritative source for knowledge level.

### SCREEN-ASMT-003 — Assessment Result
- **Purpose:** Show baseline outcome and initial learner profile.
- **Components:** Score, percentage, strengths, weaknesses, initial level, recommended direction, continue button.
- **API Dependency:** Response from `ASMT-002`, or `ASMT-003 [TBD] GET /api/v1/assessment/{subjectId}/result`.
- **Navigation:** Continue → Personalized Learning Path.

### SCREEN-LEARN-001 — Personalized Learning Path
- **Purpose:** The signature "adventure map" screen visualizing topic progression.
- **Components:** Node-based path visualization; each node shows state: Locked 🔒, Available 🔓, In Progress, Completed ✓, Recommended, Needs Revision.
- **API Dependency:** `PATH-001 [TBD]` — `GET /api/v1/learning-path/{subjectId}`.
- **Response:** Array of nodes `{ id, title, status, order }` — statuses **always** come from backend.
- **Loading:** Skeleton path with placeholder nodes.
- **Empty:** "Your path will appear once your assessment is complete."
- **Navigation:** Tap available/in-progress node → Topic Detail; locked node → disabled with tooltip explaining prerequisite.

### SCREEN-LEARN-002 — Topic Detail
- **Purpose:** Overview of a single topic before starting the lesson.
- **Components:** Topic title, description, status, "Start Lesson" / "Continue" CTA.
- **API Dependency:** `TOPIC-001 [TBD]` — `GET /api/v1/topics/{topicId}`.
- **Navigation:** → Lesson.

### SCREEN-LEARN-003 — Lesson
- **Purpose:** Present backend/AI-provided educational content.
- **Components:** Title, explanation, examples, key concepts, illustrations (if provided), hints, "Practice" CTA.
- **API Dependency:** `LESSON-001 [TBD]` — `GET /api/v1/topics/{topicId}/lesson`.
- **Rule:** If Gemini-generated, frontend receives an already-structured response from Spring Boot — **never** calls Gemini directly.
- **Error/Empty:** Handle missing or malformed AI content gracefully (see §14) — show fallback message, never a blank/broken screen.
- **Navigation:** "Practice" → Challenge/Quiz.

### SCREEN-CHAL-001 — Challenge / Quiz
- **Purpose:** Deliver the adaptive challenge for the current topic.
- **Components:** Question, question number/progress, difficulty indicator (if provided), options, selected state, submit, next, exit-confirmation dialog. No fixed assumption about question count — structure comes from backend.
- **API Dependency:** `QUIZ-001 [TBD]` — `GET /api/v1/quiz/{topicId}`; submission via `QUIZ-002 [TBD]` — `POST /api/v1/quiz/{quizId}/submit`.
- **Request:** `{ answers: [{ questionId, selectedOptionId }] }`
- **Response:** Result payload (score, xpEarned, difficulty, achievements, recommendation — exact fields per API Contract).
- **Loading:** Full-screen submit indicator.

### SCREEN-CHAL-002 — Quiz Result
- **Purpose:** Communicate performance **and the adaptive decision**.
- **Components:** Score, accuracy, correct/incorrect count, XP earned, achievement unlock, topic performance, difficulty recommendation, next action, backend-provided personalized message.
- **Rule:** Result messaging (e.g., "Let's strengthen this topic first...") is **never hard-coded**; it is rendered from the backend response if the contract provides it, otherwise a neutral fallback template is used and flagged `[TBD — AI SPECIFICATION REQUIRED]`.
- **API Dependency:** Response of `QUIZ-002`.
- **Navigation:** Continue → Next Recommendation or back to Learning Path.

### SCREEN-CHAL-003 — Next Recommendation
- **Purpose:** Explicitly visualize the adaptive-loop decision.
- **Components:** Previous difficulty → performance → new recommendation (visual chain, see §15); reason text; "Continue" CTA.
- **API Dependency:** Same payload as `QUIZ-002` response (`recommendedDifficulty`, `reason`, `nextActivity`).
- **Rule:** Avoid exposing internal algorithm details — show the *decision*, not the *mechanism*.

### SCREEN-AI-001 — AI Tutor
- **Purpose:** Conversational help interface.
- **Components:** Message list (user/AI), input field, send button, typing/loading indicator, error state with retry, suggested questions, clear-conversation option (if supported).
- **API Dependency:** `AI-001 [TBD]` — `POST /api/v1/ai/tutor`.
- **Request:** `{ message, context: { subjectId, topicId } }`
- **Response:** `{ reply, relatedTopics? }`
- **Rule:** Flutter never calls Gemini directly; API key stays server-side.
- **Error Behavior:** AI timeout/unavailable → "The tutor is having trouble responding, please try again" + retry; malformed response → same fallback, never render raw/broken content.
- **Context Display:** Optional subtle indicator, e.g. "Learning context: Computer Networks → IP Addressing." Never display internal prompts, hidden instructions, or API keys.

### SCREEN-AI-002 — AI Explanation / Hint State
- **Purpose:** Inline AI-provided hint or clarification within a lesson/quiz.
- **Components:** Expandable hint panel, loading state, error fallback.
- **API Dependency:** Same pattern as AI-001, scoped to current question/topic.

### SCREEN-GAME-001 — Achievements
- **Purpose:** Display unlocked and locked badges.
- **Components:** Badge grid, name, description, locked/unlocked visual state.
- **API Dependency:** `ACH-001 [TBD]` — `GET /api/v1/achievements`.
- **Navigation:** Tap badge → Badge Detail.

### SCREEN-GAME-002 — Badge Detail
- **Purpose:** Show detail of a single achievement.
- **Components:** Badge image, name, description, unlock date (if unlocked), progress toward unlock (if locked).
- **API Dependency:** `ACH-002 [TBD]` — `GET /api/v1/achievements/{id}`.

### SCREEN-GAME-003 — Streak / Progress Widget
- **Purpose:** Reusable component showing current streak and milestones (embedded in Dashboard/Profile).
- **API Dependency:** `STREAK-001 [TBD]` — `GET /api/v1/streak`.

### SCREEN-ANLY-001 — Progress Dashboard
- **Purpose:** Overall learner analytics.
- **Components:** Overall progress, quiz accuracy, completed lessons, difficulty progression, streak, weak/strong topics. Use charts only where they add clarity — no chart overload.
- **API Dependency:** `PROG-001 [TBD]` — `GET /api/v1/progress`.

### SCREEN-ANLY-002 — Topic Performance
- **Purpose:** Drill-down performance per topic.
- **API Dependency:** `PROG-002 [TBD]` — `GET /api/v1/progress/{topicId}`.

### SCREEN-USER-001 — Profile
- **Purpose:** Learner identity and stats summary.
- **Components:** Name, email, level, XP, streak, achievements, learning statistics.
- **API Dependency:** `USER-001 [TBD]` — `GET /api/v1/profile`.

### SCREEN-USER-002 — Settings
- **Purpose:** Account and app preferences.
- **Components:** Theme toggle, notification settings (if implemented — see §18), account settings, logout.
- **API Dependency:** `USER-002 [TBD]`, logout via `AUTH-003 [TBD] POST /api/v1/auth/logout`.
- **Success (logout):** Clear stored token and all cached learner state → Login.

---

## 11. API Dependency Matrix

| Screen | Feature | API ID | Method | Auth Required |
|---|---|---|---|---|
| Splash | Token validation | AUTH-000 [TBD] | GET/POST | No |
| Login | Login | AUTH-001 [TBD] | POST | No |
| Registration | Register | AUTH-002 [TBD] | POST | No |
| Settings | Logout | AUTH-003 [TBD] | POST | Yes |
| Dashboard | Dashboard data | DASH-001 [TBD] | GET | Yes |
| Subject Selection | List subjects | SUBJ-001 [TBD] | GET | Yes |
| Assessment Intro | Assessment meta | ASMT-001 [TBD] | GET | Yes |
| Assessment Question | Submit assessment | ASMT-002 [TBD] | POST | Yes |
| Assessment Result | Assessment result | ASMT-003 [TBD] | GET | Yes |
| Learning Path | Path nodes | PATH-001 [TBD] | GET | Yes |
| Topic Detail | Topic info | TOPIC-001 [TBD] | GET | Yes |
| Lesson | Lesson content | LESSON-001 [TBD] | GET | Yes |
| Quiz | Quiz questions | QUIZ-001 [TBD] | GET | Yes |
| Quiz | Submit quiz | QUIZ-002 [TBD] | POST | Yes |
| AI Tutor | AI conversation | AI-001 [TBD] | POST | Yes |
| Achievements | List achievements | ACH-001 [TBD] | GET | Yes |
| Badge Detail | Achievement detail | ACH-002 [TBD] | GET | Yes |
| Streak Widget | Streak data | STREAK-001 [TBD] | GET | Yes |
| Progress Dashboard | Progress summary | PROG-001 [TBD] | GET | Yes |
| Topic Performance | Topic-level progress | PROG-002 [TBD] | GET | Yes |
| Profile | Profile data | USER-001 [TBD] | GET | Yes |
| Settings | Update settings | USER-002 [TBD] | PUT/PATCH | Yes |

> All API IDs are placeholders. **Before implementation, every row must be reconciled against the finalized API Contract document.** Do not implement against this table alone.

---

## 12. Data Flow Pattern (applies to every major feature)

```
User Action → Flutter UI → Frontend State → API Request
   → Spring Boot → Backend / AI / Database
   → API Response → Flutter Model → State Update → UI Update
```

---

## 13. Frontend Data Models

| Model | Key Fields (indicative — confirm against API Contract) | Source API |
|---|---|---|
| User | id, name, email, level, xp | AUTH-*, USER-001 |
| Subject | id, name, description, icon, progress, level | SUBJ-001 |
| LearningPath / LearningNode | id, title, status, order | PATH-001 |
| Lesson | topicId, title, explanation, examples, hints | LESSON-001 |
| Question | id, text, options, order | ASMT-002, QUIZ-001 |
| Quiz / QuizAttempt | quizId, questions[], answers[] | QUIZ-001/002 |
| QuizResult | score, accuracy, xpEarned, difficulty, achievements[] | QUIZ-002 |
| Progress | overallProgress, weakTopics[], strongTopics[] | PROG-001/002 |
| Achievement | id, name, description, unlocked, unlockedAt | ACH-001/002 |
| Streak | currentStreak, milestones[] | STREAK-001 |
| Recommendation | recommendedDifficulty, reason, nextActivity | QUIZ-002 |
| AiTutorMessage | role, content, timestamp | AI-001 |

Rule: **no model field is added unless it exists in the API Contract.** Undefined fields are marked `[TBD]`, not guessed.

---

## 14. State Management

Domains to keep logically separate (technology choice `[TBD — REQUIRES DECISION]`, e.g. Provider/Riverpod/Bloc — pick based on team familiarity and complexity, not novelty):

- **Auth State:** logged in / logged out / loading / session expired
- **User State:** profile, XP, level, streak
- **Learning State:** subject, learning path, current topic, progress
- **Quiz State:** questions, answers, current index, submission state, result
- **AI Tutor State:** conversation history, loading, error

Avoid a single global state object — keep these as independent, feature-scoped stores.

---

## 15. AI Integration Requirements

```
Flutter AI Tutor → POST /api/v1/ai/tutor → Spring Boot
   → AI Orchestration → Gemini → Validated Response
   → Spring Boot → Flutter
```

- Flutter **never** calls Gemini directly; the API key never touches the client.
- Frontend must gracefully handle: missing content, malformed response, empty response, AI timeout, AI service unavailable (see §19 error model).
- Never surface: API keys, hidden prompts, internal model configuration, backend reasoning, raw unvalidated AI output.

---

## 16. Adaptive Learning Integration

Backend determines difficulty, weak topics, recommendations, and next activity. Frontend **only visualizes**.

```
Previous Difficulty → Performance % → New Recommendation (backend-computed)
```

Example backend response → frontend rendering:

```json
{
  "recommendedDifficulty": "EASY",
  "reason": "Weak performance in IP Addressing",
  "nextActivity": { "type": "PRACTICE", "topic": "IP Addressing" }
}
```
→ *"Let's strengthen IP Addressing before moving forward."*

Never expose internal algorithm details — show the decision, not the mechanism.

---

## 17. Gamification UI

- **XP:** current XP, XP earned this session, progress bar to next level.
- **Level:** current level, progress to next.
- **Achievements:** badge, name, description, locked/unlocked state.
- **Streak:** current streak, milestones, recent activity.
- **Rewards/coins:** only if approved in Master Spec — otherwise `[OPTIONAL — REQUIRES MVP APPROVAL]`.

Backend remains authoritative for all reward calculations; frontend displays only.

---

## 18. Progress & Analytics

Metrics: overall progress, topic mastery, quiz accuracy, completed lessons, difficulty progression, streak, recent performance, weak/strong topics. Use charts sparingly — only where they materially improve comprehension.

---

## 19. Global UI States & Error Handling

| State | Behavior |
|---|---|
| Loading | Progress indicators / skeletons + contextual message |
| Empty | e.g. "No learning activity yet. Start your first challenge." |
| Error | e.g. "We couldn't load your learning path." + Retry / Go back |
| Offline | Explicit "You're offline" — distinct from server error |
| Unauthorized (401) | Clear session → redirect to Login |
| Session Expired | Clear invalid auth state, prompt re-login |

**Centralized error model** (single API client normalizes all backend errors — no per-screen parsing):

```
ApiException
 ├── Unauthorized
 ├── Forbidden
 ├── Validation
 ├── NotFound
 ├── Conflict
 ├── ServerError
 ├── Timeout
 └── NetworkError
```

Each type maps to one consistent UI behavior across the whole app.

---

## 20. Authentication

```
Login → Receive access token → Secure storage → Attach token to
authenticated requests → Handle expiration → Logout
```

- Tokens stored via secure storage only (never plain shared preferences for sensitive tokens).
- Never hard-code JWTs, Gemini keys, DB credentials, or backend secrets anywhere in the Flutter codebase.
- On 401 from any endpoint: clear session, route to Login.

---

## 21. Security Requirements

- No secrets, DB credentials, or Gemini credentials in the client.
- HTTPS enforced in production.
- Secure token storage; input validation on all forms; graceful handling of session expiry.
- No internal error detail exposed to the user; no sensitive data in logs.

---

## 22. Accessibility

- Adequate color contrast; readable font sizes; minimum 44x44 touch targets.
- Semantic labels for screen readers on all interactive elements.
- No color-only status communication (e.g., locked/completed nodes need icon + color).
- Clear, plain-language error messages.

---

## 23. Performance Requirements

- Avoid unnecessary widget rebuilds; lazy-load long lists (achievements, path nodes).
- Optimize images/illustrations; minimize animation overhead.
- Handle network latency gracefully (timeouts, skeletons); avoid blocking the UI thread.
- Cache only non-sensitive data, and only where it improves perceived performance.

---

## 24. Offline Behavior (MVP scope)

If connectivity is unavailable: show explicit offline state, preserve unsent local UI state where safe, allow navigation to cached content **only if implemented**, provide retry. Do not claim full offline learning support — that is out of MVP scope unless explicitly approved in the Master Specification.

---

## 25. Notifications

Treated as **optional** for MVP. If implemented later, each notification needs: type, trigger, backend requirement, permission requirement, navigation destination. Not part of core MVP unless approved.

---

## 26. Flutter Folder Structure

```
mobile/gamelearn_app/
├── lib/
│   ├── core/
│   │   ├── config/       # environment config
│   │   ├── constants/
│   │   ├── theme/        # design system (§27)
│   │   ├── network/      # API client, interceptors
│   │   ├── storage/      # secure token storage
│   │   ├── errors/       # ApiException hierarchy
│   │   └── utils/
│   ├── shared/
│   │   ├── widgets/      # buttons, cards, indicators
│   │   ├── models/       # shared data models
│   │   └── components/
│   ├── features/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   ├── subjects/
│   │   ├── assessment/
│   │   ├── learning_path/
│   │   ├── lessons/
│   │   ├── quiz/
│   │   ├── ai_tutor/
│   │   ├── achievements/
│   │   ├── progress/
│   │   └── profile/
│   └── main.dart
├── assets/{images,icons,animations,fonts}/
├── test/
└── pubspec.yaml
```

Each `features/*` module owns its own UI, state, and API calls for that domain; `core/` and `shared/` hold cross-cutting concerns and reusable pieces only.

---

## 27. UI Design System

- **Typography:** Display / Heading / Subheading / Body / Caption hierarchy.
- **Spacing:** consistent scale (e.g., 4/8/12/16/24/32).
- **Border radius & shadows:** defined once, reused everywhere.
- **Icons:** one consistent icon family.
- **Semantic colors:** Primary, Secondary, Background, Surface, Text, Success, Warning, Error, XP/Reward, Locked, Completed.
- **Visual identity target:** "Learning Adventure + Intelligent Technology" — not a generic quiz-app look.

---

## 28. Reusable Component System

Buttons, cards, XP indicator, level indicator, progress bars, streak card, achievement card, quiz option tile, learning-path node, dialogs, error widget, loading widget, empty-state widget. No screen should re-implement these individually.

---

## 29. Responsive / Device Requirements

Design and test for small/standard/large Android phones and tablets where practical. Prevent overflow, text/button clipping, keyboard overlap, incorrect scrolling, and unsafe-area issues in both portrait and applicable landscape orientations.

---

## 30. Mock API Strategy

```
API Contract → Mock Response → Flutter UI → UI Testing → Real Spring Boot API
```

Mock data must mirror the API Contract exactly — no invented fields. This lets Member 1 build ahead of backend completion without drift.

---

## 31. Testing Strategy

| Type | Covers |
|---|---|
| Widget Tests | UI rendering, interactions, validation, state changes |
| Unit Tests | Model parsing, validators, state logic, response mapping |
| API Integration Tests | Correct request shape, response parsing, auth, error handling |
| End-to-End | Register → Login → Select subject → Assessment → Learning path → Lesson → Quiz → Result → Adaptive recommendation → XP → Achievement → Dashboard update |

---

## 32. Frontend-Backend Integration & Conflict Resolution

- Frontend must use **exactly** the fields defined in the API Contract — e.g. if the contract says `xpEarned`, Flutter uses `xpEarned`, not a guessed alternative.
- If a mismatch is found (e.g., frontend expects `xpEarned`, backend returns `xp`), do **not** silently patch the frontend. Log it as:

```
CONTRACT ISSUE
API: QUIZ-002
Expected: xpEarned
Actual: xp
Status: REQUIRES RESOLUTION
```

- Resolution order: **API Contract updated → Backend updated → Frontend updated → Tests updated → Integration verified.**

---

## 33. Development Phases

1. Project setup — Flutter, theme, navigation, architecture, shared components
2. Authentication — Splash, Onboarding, Login, Register
3. Core — Dashboard, Profile, Subject Selection
4. Assessment — Assessment UI, Results
5. Learning — Learning Path, Topics, Lessons
6. Challenges — Quiz, Result, Recommendation
7. Gamification — XP, Levels, Achievements, Streaks
8. AI — AI Tutor, Explanations, Recommendation display
9. Analytics — Progress, Topic Mastery, Performance
10. Integration & Testing — Real APIs, end-to-end flow, bug fixing, device testing

---

## 34. Definition of Done (per feature)

- [ ] UI implemented [ ] Navigation implemented [ ] API integration matches contract (request & response)
- [ ] Loading / Error / Empty states implemented [ ] Auth handled [ ] Validation implemented
- [ ] Mock-data tested [ ] Real-API tested [ ] Device-tested, no overflow
- [ ] No runtime/console errors [ ] Integration test passed

---

## 35. Frontend Developer Rules (Member 1)

1. Do not modify backend code.
2. Do not access MySQL directly.
3. Do not call Gemini directly.
4. Do not invent API endpoints or response fields.
5. Do not hard-code backend-generated learning paths or adaptive decisions.
6. Do not hard-code authoritative XP.
7. Use reusable widgets; follow the approved folder structure.
8. Follow the API Contract; report contract conflicts immediately via §32's format.
9. Write tests for every major feature; do not merge broken code.
10. Do not modify shared contracts without approval.

---

## 36. Open Questions / TBD Items

- Final API Contract for all endpoints listed in §11 — **all currently placeholders.**
- State-management library choice (§14).
- "Forgot password" flow — not defined in current inputs.
- Reward/coin system — optional, pending MVP approval.
- Notification system — optional, out of MVP unless approved.
- Offline content caching scope — MVP defines "no full offline support" until stated otherwise.
- Exact AI Tutor response schema and error taxonomy from AI Specification.
- Adaptive Learning Specification's exact recommendation payload shape (used in §16, §10 Quiz Result/Next Recommendation).

Anything not resolved above must remain marked `[TBD]` in code and PRs until the corresponding contract document is finalized — do not silently make architectural decisions in its place.

---


---

## 37. PRODUCT EXPANSION — CORE CS LEARNING UNIVERSE

### 37.1 Product Vision

GameLearn AI is not intended to be a fixed five-subject LMS.

The long-term product model is:

**Curated Core CS Subject Universe + AI-Powered Long-Tail Subject Discovery + Closed-Loop Adaptive Learning.**

The curated Core CS Subject Universe is the primary learning catalog. It should contain a broad set of subjects that a Computer Science / technical learner commonly needs.

Examples include:

- C Programming
- C++
- Python
- Java
- Object-Oriented Programming
- Data Structures
- Algorithms
- DBMS
- Operating Systems
- Computer Networks
- Theory of Computation
- Compiler Design
- Computer Organization / Architecture
- Artificial Intelligence
- Machine Learning
- Web Technologies
- Cyber Security
- Cryptography
- Software Engineering
- Cloud Computing
- Aptitude / Technical Aptitude
- and other approved core technical subjects.

The exact catalog must remain backend-authoritative and extensible.

The frontend MUST NOT encode a permanent fixed list in Dart.

### 37.2 Why the Core Catalog Is Curated

The purpose of the curated catalog is quality and depth.

A learner selecting a core subject should be able to progress through a structured learning journey rather than receive a random collection of AI-generated pages.

Example DBMS journey:

DBMS
→ Database Fundamentals
→ ER Modeling
→ Relational Model
→ SQL
→ Keys and Constraints
→ Normalization
→ Transactions
→ Concurrency Control
→ Indexing
→ Query Processing
→ Recovery
→ Advanced Database Concepts

The exact topic graph is backend/content-authority controlled.

The frontend renders the graph and learner state.

### 37.3 Subject Completion Philosophy

"Learning a subject" does NOT mean merely opening a lesson and completing one quiz.

A supported subject journey should progressively expose:

1. Baseline assessment
2. Learner knowledge profile
3. Personalized learning path
4. Topic learning
5. Practice
6. Challenge
7. Performance analysis
8. Adaptive recommendation
9. Weak-topic reinforcement
10. Difficulty adaptation
11. AI tutor assistance
12. Reassessment
13. Mastery progression
14. Subject-level progress

The frontend must make this progression visible.

### 37.4 Subject-Level Mastery

When backend contracts support mastery information, display:

- subject progress
- topic mastery
- mastered topics
- weak topics
- in-progress topics
- recommended topics
- difficulty progression
- assessment history
- quiz performance
- learning streak
- XP/level progression.

Flutter MUST display backend-authoritative values.

Flutter MUST NOT calculate authoritative mastery.

---

## 38. AI-POWERED LONG-TAIL SUBJECT DISCOVERY

### 38.1 Product Rule

Not every possible academic subject should be placed permanently in the curated Core CS catalog.

Examples include:

- Fluid Mechanics
- Thermodynamics
- Civil Engineering subjects
- Mechanical Engineering subjects
- Electrical Engineering subjects
- other non-core or long-tail academic subjects.

These subjects may be discovered through an AI-powered subject search/discovery experience IF the backend/API contract supports such functionality.

### 38.2 Discovery UX

The Dashboard / Subject Hub may provide:

**"Can't find your subject?"**

→ Search / Ask AI

Example:

> Fluid Mechanics

The system may return:

- subject availability
- AI-generated learning scope
- recommended starting level
- proposed learning path
- supported/not-supported state

### 38.3 Strict Architecture Rule

The frontend MUST NOT directly call Gemini.

The frontend MUST NOT generate authoritative educational curricula locally.

The frontend MUST NOT pretend that an unsupported subject is fully supported.

The flow must be:

Flutter
→ Spring Boot
→ AI / subject discovery service
→ validated backend response
→ Flutter.

If this backend capability does not currently exist, implement only the UX boundary and mark the API:

`[TBD — SUBJECT DISCOVERY API REQUIRED]`

DO NOT invent an endpoint.

### 38.4 Discovery Result States

Support:

- Supported
- Ready to start
- Generating
- Not supported
- Failed
- Retry
- Authentication required
- Network failure.

---

## 39. ADAPTIVE LEARNING DEPTH

### 39.1 Core Requirement

The defining value of GameLearn AI is not subject count.

The defining value is:

**The system changes the learner's future learning experience according to demonstrated behavior and performance.**

The adaptive loop is:

Assessment
→ Learner Profile
→ Learning Path
→ Activity
→ Performance
→ Weakness Detection
→ Backend Adaptive Decision
→ Recommendation
→ Difficulty Adjustment
→ Reinforcement / Advancement
→ Updated Profile.

### 39.2 Example — DBMS

A learner begins DBMS.

Baseline assessment reveals:

- SQL: strong
- ER modeling: medium
- Normalization: weak
- Transactions: unknown

The backend may produce a path emphasizing normalization.

After learning and quiz attempts, the backend may determine that normalization requires reinforcement.

The learner should see a meaningful explanation such as:

> "Your recent performance shows normalization needs more practice, so your next challenge focuses on normalization."

Only display a reason if the backend contract provides one. Otherwise use an approved neutral presentation.

### 39.3 Difficulty Adaptation

The system may adapt:

- EASY
- MEDIUM
- HARD

or another backend-defined difficulty model.

Flutter only renders the returned decision.

Flutter MUST NOT implement local rules such as:

`score > 80 => HARD`

### 39.4 Behavior Signals

Where the backend contract provides them, the system may consider:

- correctness
- repeated mistakes
- topic performance
- assessment performance
- quiz performance
- completion
- revision need
- difficulty progression
- learning history
- AI tutor interaction context.

Frontend should visualize outcomes, not infer hidden learner psychology.

---

## 40. WEAKNESS → RECOMMENDATION EXPERIENCE

The application must make the adaptive relationship visible.

Preferred conceptual UI:

**YOU ARE STRONG IN**
- SQL

**NEEDS PRACTICE**
- Normalization

**NEXT RECOMMENDED MISSION**
- Normalization Fundamentals

**CURRENT DIFFICULTY**
- MEDIUM

**WHY**
- Backend-provided reason, if available.

**ACTION**
- Start Recommended Challenge

This should be reusable across subjects.

Do not hard-code DBMS-specific UI.

---

## 41. SUBJECT SEARCH INFORMATION ARCHITECTURE

The subject experience should support two complementary paths:

### Path A — Curated Core Learning

Dashboard
→ Core Subjects
→ Subject
→ Assessment
→ Personalized Path
→ Learn
→ Challenge
→ Adapt
→ Mastery.

### Path B — Long-Tail Discovery

Dashboard
→ Search Subject
→ AI/Backend Discovery
→ Supported/Generated/Unavailable result
→ Start if supported.

The two paths must not be confused.

The curated catalog is the primary quality-controlled learning experience.

AI discovery is a controlled expansion mechanism.

---

## 42. SUBJECT CATALOG UX

The Subject Hub should avoid becoming a wall of cards.

Use meaningful grouping such as:

- Programming
- Data Structures & Algorithms
- Databases
- Systems
- Networks
- AI & ML
- Web
- Security
- Theory
- Software Engineering
- Aptitude
- Other Core Technical Areas.

Exact categories must be backend/content-authority compatible.

Provide:

- search
- category filtering
- recently learned
- recommended
- in-progress
- mastered
- new.

Do not hard-code category membership unless explicitly approved by the backend/content contract.

---

## 43. LEARNING A SUBJECT "PROPERLY"

The product must NOT claim that completing a finite set of screens means academic mastery.

Instead use the product concept:

**Structured adaptive subject journey.**

For each supported core subject, the intended architecture should allow:

1. Curriculum/topic graph
2. Baseline assessment
3. Personalized entry point
4. Topic lessons
5. Practice
6. Quizzes
7. Performance analysis
8. Weak-topic reinforcement
9. Adaptive difficulty
10. AI explanation/tutor
11. Reassessment
12. Mastery tracking.

The actual curriculum depth is a content/backend responsibility.

Flutter must make the depth navigable and understandable.

---

## 44. ADAPTIVE REASSESSMENT

Where supported by backend APIs, provide a reassessment loop.

Example:

Initial assessment
→ Weak topic detected
→ Learning activity
→ Practice
→ Quiz
→ Recommendation
→ Reassessment
→ Updated mastery.

The UI should make it possible to see that the learner improved.

Do not create fake mastery progression.

---

## 45. CROSS-SUBJECT LEARNER PROFILE

The learner profile should eventually represent multiple subjects.

Example:

Programming       82%
DBMS               64%
Operating Systems  41%
Networks            71%
AI/ML              28%

The dashboard can then surface:

**"Your strongest area is Programming."**

**"Operating Systems needs attention."**

Only show such statements if the backend supplies the underlying data or an approved backend recommendation.

The frontend must not derive authoritative learner ranking itself.

---

## 46. SUBJECT-AGNOSTIC FRONTEND ARCHITECTURE

The frontend must be designed so that adding a new subject requires:

**Backend/content configuration**

NOT:

**Creating a new Flutter screen.**

A subject should be data-driven:

Subject
→ Topic list
→ Topic metadata
→ Lesson
→ Quiz
→ Result
→ Recommendation
→ Progress.

Avoid code such as:

`if subject == "DBMS" ...`

for core learning behavior.

Use IDs/types/statuses returned by the API.

---

## 47. DEMO QUALITY TARGET

For demonstrations, Programming and at least one additional fully seeded core subject should be sufficiently complete to demonstrate the entire adaptive loop.

A strong demonstration should show:

1. New learner
2. Assessment
3. Weakness discovery
4. Personalized path
5. Topic learning
6. Quiz
7. Poor/strong performance
8. Backend adaptation
9. Changed recommendation
10. XP/achievement
11. AI tutor
12. Return to learning path.

The demo must show adaptation rather than merely show screens.

---

## 48. PRODUCT QUALITY PRINCIPLE

GameLearn AI should be judged by:

**Depth of adaptive learning experience**

rather than:

**Number of subject cards.**

Adding subjects without curriculum depth does not satisfy the product vision.

Adding a new subject must eventually produce a reusable adaptive journey.

---

## 49. IMPLEMENTATION PRIORITY FOR FUTURE PHASES

Future development should follow:

### Phase A — Stabilize Current Foundation
Authentication
Dashboard
Subject Hub
Assessment
Learning Path
Lesson
Quiz
Result
AI Tutor
Gamification.

### Phase B — Expand Core Subject Catalog
Backend-authorized core subjects.

### Phase C — Deepen One Subject
At least one subject should demonstrate a multi-topic adaptive journey.

### Phase D — Adaptive Reinforcement
Weakness detection
difficulty adaptation
recommendations
reassessment.

### Phase E — Subject Discovery
AI-powered long-tail subject search, only after backend API is available.

### Phase F — Cross-Subject Learner Intelligence
Unified learner profile and recommendations.

### Phase G — Mobile/Web QA
Full device and browser verification.

---

## 50. NON-GOALS

The frontend must NOT:

- become an AI-generated generic course generator
- promise academic certification
- claim mastery without backend evidence
- fabricate curricula
- invent questions
- fabricate recommendations
- call Gemini directly
- calculate adaptive difficulty
- calculate authoritative mastery
- hard-code a finite permanent subject list
- create separate code paths for every subject.

---

## 51. UPDATED SUBJECT-EXPANSION DEFINITION OF DONE

A new core subject is considered frontend-ready when:

- [ ] Subject appears from backend catalog
- [ ] Subject can be selected
- [ ] Assessment entry works
- [ ] Assessment questions load from backend
- [ ] Assessment result renders
- [ ] Personalized path renders
- [ ] Topic navigation works
- [ ] Lesson loads
- [ ] Challenge loads
- [ ] Quiz submission works
- [ ] Result renders
- [ ] Backend recommendation renders
- [ ] AI tutor can receive correct subject/topic context
- [ ] Progress renders
- [ ] Gamification renders
- [ ] Loading/error/empty states work
- [ ] Mobile layout works
- [ ] Web layout works where supported
- [ ] No subject-specific frontend business logic was duplicated.

---

## 52. UPDATED PRODUCT DEFINITION OF DONE

GameLearn AI is not considered product-complete merely because all screens exist.

The product must demonstrate at least one complete adaptive learning loop:

**Assessment → Weakness → Personalized Path → Learning → Challenge → Performance → Adaptation → Recommendation → Continued Learning.**

It should also demonstrate:

**XP → Achievement → Progress → Updated Learner State.**

For the final target product, the same architecture must support a broad Core CS Subject Universe without requiring frontend redesign.


*End of Specification.*
