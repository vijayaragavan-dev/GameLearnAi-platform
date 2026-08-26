-- GameLearn AI - Programming demo content seed
-- (Database Specification sections 10-16, API Contract v1.4.0)
--
-- Deterministic curated content for the existing Programming subject
-- 11111111-1111-1111-1111-111111111101 so the frontend can demonstrate
-- subject -> topic -> lesson -> assessment (9 questions, K=3 per topic)
-- -> learning path (3 nodes) -> quiz (4 per topic) -> gamification.
--
-- UUID namespaces:
--   subjects (V11) : 111...101..105
--   topics (V12)   : 222...211..213
--   lessons        : 333...311..313
--   questions      : 444...401..412
--   quizzes        : 555...511..513
--   quiz_questions : 666...601..612
-- All rows are CURATED, is_active=true, and repeatable via Flyway's
-- run-once history (no re-insert on re-run). No user data is inserted.

-- ------------------------------------------------------------------
-- 1) Topics (3) for Programming
-- ------------------------------------------------------------------
INSERT INTO topics (id, subject_id, name, description, difficulty, display_order, is_active, created_at, updated_at) VALUES
('22222222-2222-2222-2222-222222222211', '11111111-1111-1111-1111-111111111101', 'Variables & Types', 'Fundamentals of variable declaration, primitive types, type inference, and type safety — the ground on which all Programming missions build.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222212', '11111111-1111-1111-1111-111111111101', 'Control Flow', 'Branching with if/else and pattern matching, plus iteration with for/while and early exits — how a program decides what to do next.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222213', '11111111-1111-1111-1111-111111111101', 'Functions & Scope', 'Decomposing logic into pure, reusable functions, understanding parameters, return values, lexical scope, and closures.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 2) Lessons (1 per topic, CURATED)
-- ------------------------------------------------------------------
INSERT INTO lessons (id, topic_id, title, content, summary, difficulty, source_type, is_active, created_at, updated_at) VALUES
('33333333-3333-3333-3333-333333333311', '22222222-2222-2222-2222-222222222211', 'Variables & Types — Foundations',
'Variables bind a name to a value, and types describe what kind of value a variable can hold. In statically typed languages a variable declared as int can never hold a string; in dynamically typed languages the binding is more fluid, but the underlying value still has a type.

Primitive types include integers, floating-point numbers, booleans, and characters. Compound types like arrays, lists, and objects compose primitives into structures. Choosing the right type matters: an int uses less memory than a float, and a boolean makes intent clearer than 0/1.

Type inference lets the compiler deduce the type from the initializer, so you write var count = 0 instead of int count = 0. Inference does not mean dynamic typing — the variable is still statically bound; it simply saves ceremony. A good rule is to be explicit at public boundaries (function signatures) and lean on inference locally.',
'Declare variables with the narrowest correct type, prefer inference locally, and be explicit at boundaries — type safety catches errors before the program runs.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333312', '22222222-2222-2222-2222-222222222212', 'Control Flow — Decisions & Loops',
'Control flow is how a program chooses a path. An if/else branch evaluates a boolean condition: if the condition is true the then-branch runs, otherwise the else-branch runs. Many languages also provide switch or match that dispatches on shape, which is more readable than a long chain of else-if when many cases exist.

Loops repeat a block. A for loop is ideal when the number of iterations is known — for (i = 0; i < n; i++) — while while is natural when the end condition is discovered dynamically, such as reading input until a sentinel appears. Misusing while for a counted range makes code harder to follow.

Early exits — break, continue, and return — keep nesting shallow. Prefer guard clauses: if data is invalid, return early instead of wrapping the entire function body in an if. This linearizes the happy path and reduces cognitive load. Every loop should have a clear invariant and a guarantee of termination.',
'Use if/else for two-way choice, match for many-way dispatch, for for counted iterations, while for sentinel loops, and guard clauses to keep the happy path flat.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333313', '22222222-2222-2222-2222-222222222213', 'Functions & Scope — Building Reusable Logic',
'A function encapsulates a computation: it takes parameters, executes a body, and returns a result. Pure functions depend only on their inputs and have no side effects, which makes them easy to test and to reason about. Impure functions interact with the world — I/O, mutation — and should be isolated at the edges of the system.

Scope determines where a name is visible. In lexical (static) scope, a variable is visible from its declaration to the end of the enclosing block. A closure captures variables from its defining environment even after that environment has returned — this is how callbacks remember configuration.

Prefer small functions with a single responsibility. If a function needs more than three parameters, consider bundling them into a record or object. Name functions as verbs (calculateTotal, parseInput) and keep their length short enough to read in one screen. Scope should be as narrow as possible: declare variables in the innermost block that needs them.',
'Functions should be small, pure where possible, and narrowly scoped — parameters bundle when too many, closures capture deliberately, names are verbs.',
'MEDIUM', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 3) Questions (4 per topic = 12, MCQ, CURATED, is_active true)
-- ------------------------------------------------------------------
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at) VALUES
-- Variables & Types (EASY)
('44444444-4444-4444-4444-444444444401', '22222222-2222-2222-2222-222222222211', 'Which declaration correctly creates an immutable integer constant?', 'MCQ', 'EASY', '{"options": ["const int MAX = 100;", "var MAX = 100;", "let MAX = 100;", "int MAX := 100;"]}', 'const int MAX = 100;', 'const (or final) signals immutability; var/let without const are mutable.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444402', '22222222-2222-2222-2222-222222222211', 'What is type inference?', 'MCQ', 'EASY', '{"options": ["Compiler deduces type from initializer", "Type is checked only at runtime", "Variables have no type", "Types are guessed randomly"]}', 'Compiler deduces type from initializer', 'Inference is compile-time deduction from the initializer, not dynamic typing.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444403', '22222222-2222-2222-2222-222222222211', 'Which type best represents a true/false decision?', 'MCQ', 'EASY', '{"options": ["boolean", "int", "char", "float"]}', 'boolean', 'Boolean has exactly two values and communicates intent without encoding tricks.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444404', '22222222-2222-2222-2222-222222222211', 'Why prefer explicit types at public function boundaries?', 'MCQ', 'EASY', '{"options": ["Documents the contract for callers", "It makes code run faster in all languages", "Implicit types are not allowed there", "It disables type checking"]}', 'Documents the contract for callers', 'Explicit signatures are documentation and preserve API stability; inference is best locally.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Control Flow (EASY)
('44444444-4444-4444-4444-444444444405', '22222222-2222-2222-2222-222222222212', 'Which construct is clearest for many-way dispatch on shape?', 'MCQ', 'EASY', '{"options": ["match/switch", "nested if/else", "goto", "while loop"]}', 'match/switch', 'match/switch expresses multi-way dispatch declaratively; long if/else chains obscure structure.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444406', '22222222-2222-2222-2222-222222222212', 'When is a for loop preferred over while?', 'MCQ', 'EASY', '{"options": ["When the iteration count is known", "When reading until a sentinel", "When recursion is required", "Never — while is always preferred"]}', 'When the iteration count is known', 'for loops encode known bounds (i < n) directly; while is for dynamic termination.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444407', '22222222-2222-2222-2222-222222222212', 'What does a guard clause achieve?', 'MCQ', 'EASY', '{"options": ["Returns early on invalid input to keep the happy path flat", "Wraps the whole function in try/catch", "Inverts the loop direction", "Marks code as deprecated"]}', 'Returns early on invalid input to keep the happy path flat', 'Guard clauses exit on edge cases first, preventing deep nesting of the main logic.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444408', '22222222-2222-2222-2222-222222222212', 'Which loop guarantees at least one execution?', 'MCQ', 'EASY', '{"options": ["do-while", "while", "for", "match"]}', 'do-while', 'do-while checks the condition after the body, so it runs once even if the condition is initially false.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Functions & Scope (MEDIUM)
('44444444-4444-4444-4444-444444444409', '22222222-2222-2222-2222-222222222213', 'What characterizes a pure function?', 'MCQ', 'MEDIUM', '{"options": ["Depends only on inputs, no side effects", "Modifies global state on each call", "Always runs in O(1) time", "Cannot be tested in isolation"]}', 'Depends only on inputs, no side effects', 'Purity makes outputs deterministic from inputs and simplifies testing and reasoning.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444410', '22222222-2222-2222-2222-222222222213', 'What does a closure capture?', 'MCQ', 'MEDIUM', '{"options": ["Variables from its defining environment", "Only its own parameters", "The entire heap", "A copy of all global variables"]}', 'Variables from its defining environment', 'Closures retain lexical bindings even after the outer function has returned.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444411', '22222222-2222-2222-2222-222222222213', 'When should parameters be bundled into a record/object?', 'MCQ', 'MEDIUM', '{"options": ["When a function takes more than three parameters", "Always — even for one parameter", "Only when recursion is used", "Only when the language forces it"]}', 'When a function takes more than three parameters', 'Bundling clarifies call sites and groups coherent data; it also eases future evolution.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444412', '22222222-2222-2222-2222-222222222213', 'What is the narrowest correct scope for a loop counter?', 'MCQ', 'MEDIUM', '{"options": ["Inside the loop header/block", "At the top of the file as global", "As a field of an unrelated class", "In the caller of the function"]}', 'Inside the loop header/block', 'Scope should be minimal: declare the counter where it is used so it does not leak.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 4) Quizzes (1 per topic, CURATED)
-- ------------------------------------------------------------------
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at) VALUES
('55555555-5555-5555-5555-555555555511', '22222222-2222-2222-2222-222222222211', 'Variables & Types Challenge', 'Apply type declarations, inference, and primitive choices across four calibrated questions.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555512', '22222222-2222-2222-2222-222222222212', 'Control Flow Challenge', 'Prove mastery of branching, loops, and guard clauses through four scenario-based questions.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555513', '22222222-2222-2222-2222-222222222213', 'Functions & Scope Challenge', 'Demonstrate function design, purity, and scope reasoning under medium difficulty.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 5) QuizQuestions (4 per quiz, same-topic linking, ordered 1..4)
-- ------------------------------------------------------------------
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at) VALUES
-- Quiz 1 -> Variables & Types questions 401..404
('66666666-6666-6666-6666-666666666601', '55555555-5555-5555-5555-555555555511', '44444444-4444-4444-4444-444444444401', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666602', '55555555-5555-5555-5555-555555555511', '44444444-4444-4444-4444-444444444402', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666603', '55555555-5555-5555-5555-555555555511', '44444444-4444-4444-4444-444444444403', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666604', '55555555-5555-5555-5555-555555555511', '44444444-4444-4444-4444-444444444404', 4, CURRENT_TIMESTAMP),
-- Quiz 2 -> Control Flow questions 405..408
('66666666-6666-6666-6666-666666666605', '55555555-5555-5555-5555-555555555512', '44444444-4444-4444-4444-444444444405', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666606', '55555555-5555-5555-5555-555555555512', '44444444-4444-4444-4444-444444444406', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666607', '55555555-5555-5555-5555-555555555512', '44444444-4444-4444-4444-444444444407', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666608', '55555555-5555-5555-5555-555555555512', '44444444-4444-4444-4444-444444444408', 4, CURRENT_TIMESTAMP),
-- Quiz 3 -> Functions & Scope questions 409..412
('66666666-6666-6666-6666-666666666609', '55555555-5555-5555-5555-555555555513', '44444444-4444-4444-4444-444444444409', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666610', '55555555-5555-5555-5555-555555555513', '44444444-4444-4444-4444-444444444410', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666611', '55555555-5555-5555-5555-555555555513', '44444444-4444-4444-4444-444444444411', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666612', '55555555-5555-5555-5555-555555555513', '44444444-4444-4444-4444-444444444412', 4, CURRENT_TIMESTAMP);
