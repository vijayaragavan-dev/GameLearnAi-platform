-- GameLearn AI - Phase 10: second content round for the six new subjects.
-- Adds real, syllabus-aligned MCQs on a SECOND representative topic per new
-- unit (29 topics x 3 questions = 87 questions), plus one CURATED quiz per
-- topic (29 quizzes) with deterministic quiz_question links. Together with
-- V27, every new unit now has two question-backed topics (58 of 134 topics).
-- Deterministic reserved namespaces continuing the existing blocks:
--   questions      : 44444444-...-570..656 (87)
--   quizzes        : 55555555-...-573..601 (29)
--   quiz_questions : 66666666-...-748..834 (87)
-- Every statement is INSERT...SELECT...WHERE NOT EXISTS (H2 + MySQL
-- portable): re-running never duplicates. Additive only: V12/V14/V27 rows
-- are untouched. Correct-answer positions vary (never implicitly options[0]).

-- ------------------------------------------------------------------
-- 1) Questions (87)
-- ------------------------------------------------------------------

-- OOP / Data Types (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444570', '22222222-2222-2222-2222-222222222245', 'Which Java type holds a single 16-bit Unicode character?', 'MCQ', 'EASY', '{"options": ["char", "int", "String", "boolean"]}', 'char', 'char stores one UTF-16 code unit; String holds sequences.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444570');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444571', '22222222-2222-2222-2222-222222222245', 'What is the default value of an uninitialized int field?', 'MCQ', 'EASY', '{"options": ["null", "0", "undefined", "false"]}', '0', 'Numeric fields default to zero; object references default to null.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444571');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444572', '22222222-2222-2222-2222-222222222245', 'Which conversion is a widening conversion?', 'MCQ', 'EASY', '{"options": ["long to int", "double to float", "int to long", "short to byte"]}', 'int to long', 'Widening moves to a larger range without loss; the rest narrow.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444572');

-- OOP / Constructors (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444573', '22222222-2222-2222-2222-222222222250', 'What is true of every Java constructor?', 'MCQ', 'MEDIUM', '{"options": ["It must be static", "It has no return type, not even void", "It must be private", "It returns an int status"]}', 'It has no return type, not even void', 'Constructors share the class name and declare no return type.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444573');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444574', '22222222-2222-2222-2222-222222222250', 'When does Java provide a default constructor?', 'MCQ', 'MEDIUM', '{"options": ["Always, even with declared ones", "Only for abstract classes", "Never automatically", "When no constructor is declared"]}', 'When no constructor is declared', 'Declaring any constructor suppresses the implicit default.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444574');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444575', '22222222-2222-2222-2222-222222222250', 'What does a this(...) call do?', 'MCQ', 'MEDIUM', '{"options": ["Calls the parent constructor", "Terminates the program", "Calls another constructor of the same class", "Allocates native memory"]}', 'Calls another constructor of the same class', 'Constructor chaining reuses initialization logic within the class.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444575');

-- OOP / Interfaces (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444576', '22222222-2222-2222-2222-222222222256', 'Which statement about Java interfaces is true?', 'MCQ', 'MEDIUM', '{"options": ["A class extends multiple classes", "Interfaces hold mutable instance fields", "A class can implement multiple interfaces", "All interface methods must be private"]}', 'A class can implement multiple interfaces', 'Interfaces give multiple inheritance of type without state diamonds.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444576');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444577', '22222222-2222-2222-2222-222222222256', 'What may an interface contain?', 'MCQ', 'MEDIUM', '{"options": ["Instance fields with state", "Constructors", "Abstract methods and constants", "Static initializer blocks"]}', 'Abstract methods and constants', 'Interface fields are implicitly public static final; no instances exist.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444577');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444578', '22222222-2222-2222-2222-222222222256', 'What is a functional interface?', 'MCQ', 'MEDIUM', '{"options": ["Any interface in java.util", "An interface with exactly one abstract method", "An interface with no methods", "A class with one method"]}', 'An interface with exactly one abstract method', 'Single-method interfaces are lambda targets, such as Runnable.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444578');

-- OOP / Collections Framework (HARD)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444579', '22222222-2222-2222-2222-222222222260', 'Which List gives O(1) indexed access?', 'MCQ', 'HARD', '{"options": ["LinkedList", "HashSet", "ArrayList", "TreeMap"]}', 'ArrayList', 'ArrayList backs elements in an array; LinkedList walks nodes.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444579');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444580', '22222222-2222-2222-2222-222222222260', 'What is the HashMap load factor tradeoff?', 'MCQ', 'HARD', '{"options": ["It controls thread safety", "It sets the sort order", "It resizes on every put", "Higher load saves memory but risks longer chains"]}', 'Higher load saves memory but risks longer chains', 'Load factor balances table size against collision chain length.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444580');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444581', '22222222-2222-2222-2222-222222222260', 'Why use generics with collections?', 'MCQ', 'HARD', '{"options": ["They speed up hashing", "They enforce compile-time type safety", "They allow primitive type arguments directly", "They remove the need for imports"]}', 'They enforce compile-time type safety', 'Generics catch type errors at compile time instead of throwing ClassCastException.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444581');

-- OOSE / Requirements Analysis (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444582', '22222222-2222-2222-2222-222222222265', 'What is a functional requirement?', 'MCQ', 'EASY', '{"options": ["How fast the system must run", "What hardware it needs", "What the system must do", "How large the team is"]}', 'What the system must do', 'Functional requirements describe behavior; the rest constrain it.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444582');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444583', '22222222-2222-2222-2222-222222222265', 'Which requirement is non-functional?', 'MCQ', 'EASY', '{"options": ["The system shall compute tax", "The system shall store orders", "The system shall email invoices", "The system shall respond within 2 seconds"]}', 'The system shall respond within 2 seconds', 'Response time constrains quality rather than behavior.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444583');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444584', '22222222-2222-2222-2222-222222222265', 'What is requirements elicitation?', 'MCQ', 'EASY', '{"options": ["Drawing UML diagrams", "Testing releases", "Gathering requirements from stakeholders", "Writing production code"]}', 'Gathering requirements from stakeholders', 'Elicitation discovers needs through interviews, workshops and observation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444584');

-- OOSE / UML Relationships (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444585', '22222222-2222-2222-2222-222222222269', 'What does aggregation express?', 'MCQ', 'MEDIUM', '{"options": ["Inheritance of behavior", "Whole-part with independent lifetimes", "Message passing order", "Deployment nodes"]}', 'Whole-part with independent lifetimes', 'Aggregated parts outlive the whole, unlike composition.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444585');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444586', '22222222-2222-2222-2222-222222222269', 'Which arrow shows generalization?', 'MCQ', 'MEDIUM', '{"options": ["Dashed dependency arrow", "Hollow triangle pointing to the parent", "Solid diamond", "Dotted message arrow"]}', 'Hollow triangle pointing to the parent', 'Generalization points from child toward the more general parent.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444586');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444587', '22222222-2222-2222-2222-222222222269', 'What is a UML dependency?', 'MCQ', 'MEDIUM', '{"options": ["Permanent ownership", "Identical classes", "A using relationship where change may affect the client", "Runtime creation order"]}', 'A using relationship where change may affect the client', 'Dependencies are the weakest link: use without ownership.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444587');

-- OOSE / Component Diagrams (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444588', '22222222-2222-2222-2222-222222222273', 'What is a UML component?', 'MCQ', 'MEDIUM', '{"options": ["A single Java method", "A database row", "A modular replaceable part with interfaces", "A unit test"]}', 'A modular replaceable part with interfaces', 'Components encapsulate replaceable subsystems behind contracts.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444588');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444589', '22222222-2222-2222-2222-222222222273', 'What does lollipop notation show?', 'MCQ', 'MEDIUM', '{"options": ["A required interface", "A provided interface", "A package merge", "A deployment node"]}', 'A provided interface', 'The lollipop offers a service; the socket requires one.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444589');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444590', '22222222-2222-2222-2222-222222222273', 'When are component diagrams most useful?', 'MCQ', 'MEDIUM', '{"options": ["Counting source lines", "Showing large-scale structure and replaceability", "Timing method calls", "Listing test data"]}', 'Showing large-scale structure and replaceability', 'They architect deployable pieces, not code internals.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444590');

-- OOSE / Sequence Diagrams (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444591', '22222222-2222-2222-2222-222222222275', 'What runs down a sequence lifeline?', 'MCQ', 'MEDIUM', '{"options": ["Memory addresses", "Package names", "Test coverage bars", "Time with activations showing execution"]}', 'Time with activations showing execution', 'Lifelines order messages in time from top to bottom.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444591');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444592', '22222222-2222-2222-2222-222222222275', 'What does an alt fragment express?', 'MCQ', 'MEDIUM', '{"options": ["Looping forever", "A halted process", "Conditional branches among operands", "Object creation only"]}', 'Conditional branches among operands', 'alt partitions guarded alternatives like an if-else.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444592');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444593', '22222222-2222-2222-2222-222222222275', 'Which ordering do sequence diagrams emphasize?', 'MCQ', 'MEDIUM', '{"options": ["Structural nesting", "Temporal message order", "Alphabetical names", "File sizes"]}', 'Temporal message order', 'Sequences answer what happens when, not how parts nest.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444593');

-- OOSE / Design Patterns (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444594', '22222222-2222-2222-2222-222222222281', 'What problem does Singleton address?', 'MCQ', 'MEDIUM', '{"options": ["Creating families of objects", "Notifying many observers", "Ensuring exactly one instance with global access", "Swapping algorithms at runtime"]}', 'Ensuring exactly one instance with global access', 'Singleton guards construction so one instance serves all clients.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444594');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444595', '22222222-2222-2222-2222-222222222281', 'What is the Observer pattern?', 'MCQ', 'MEDIUM', '{"options": ["A single global instance", "One-to-many dependency with automatic notification", "Algorithm encapsulation", "Object cloning"]}', 'One-to-many dependency with automatic notification', 'Observers subscribe once and react to every subject change.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444595');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444596', '22222222-2222-2222-2222-222222222281', 'What is the Strategy pattern?', 'MCQ', 'MEDIUM', '{"options": ["Fixing one algorithm forever", "Encapsulating interchangeable algorithms", "Cloning prototypes", "Chaining constructors"]}', 'Encapsulating interchangeable algorithms', 'Strategy swaps behavior objects without touching clients.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444596');

-- Web / CSS3 Styling and Box Model (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444597', '22222222-2222-2222-2222-222222222289', 'What does CSS specificity decide?', 'MCQ', 'EASY', '{"options": ["Page load order", "Image compression", "Which rule wins when selectors conflict", "Server routing"]}', 'Which rule wins when selectors conflict', 'Higher-specificity selectors override weaker ones on the same element.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444597');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444598', '22222222-2222-2222-2222-222222222289', 'Which selector targets elements by class?', 'MCQ', 'EASY', '{"options": ["#idname", "elementname", ".classname", "*"]}', '.classname', 'Dots select classes; hashes select ids.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444598');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444599', '22222222-2222-2222-2222-222222222289', 'What is the box model order from inside out?', 'MCQ', 'EASY', '{"options": ["margin, border, padding, content", "content, margin, border, padding", "padding, content, margin, border", "content, padding, border, margin"]}', 'content, padding, border, margin', 'Content sits innermost, then padding, border, and margin.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444599');

-- Web / DOM Manipulation (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444600', '22222222-2222-2222-2222-222222222293', 'What does document.querySelector return?', 'MCQ', 'MEDIUM', '{"options": ["All matches as an array", "The first matching element", "The parent window", "A style sheet"]}', 'The first matching element', 'querySelector returns the first match; querySelectorAll returns all.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444600');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444601', '22222222-2222-2222-2222-222222222293', 'Which method creates an element node?', 'MCQ', 'MEDIUM', '{"options": ["document.querySelector", "document.createElement", "element.appendChild", "window.alert"]}', 'document.createElement', 'createElement builds a node before it is attached to the tree.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444601');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444602', '22222222-2222-2222-2222-222222222293', 'What does appendChild do?', 'MCQ', 'MEDIUM', '{"options": ["Removes the parent", "Attaches a node as the last child", "Clones the document", "Reloads the page"]}', 'Attaches a node as the last child', 'Appended nodes render at the end of the parent element.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444602');

-- Web / Sessions and Cookies (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444603', '22222222-2222-2222-2222-222222222297', 'Why are sessions needed in HTTP?', 'MCQ', 'MEDIUM', '{"options": ["Browsers cannot store anything", "Cookies are illegal everywhere", "HTTP is stateless across requests", "Servers lack disks"]}', 'HTTP is stateless across requests', 'Each request stands alone, so sessions tie a user journey together.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444603');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444604', '22222222-2222-2222-2222-222222222297', 'Where is a session cookie kept?', 'MCQ', 'MEDIUM', '{"options": ["On the database server", "In server source code", "In the browser and sent with requests", "In DNS records"]}', 'In the browser and sent with requests', 'The browser returns the session id so the server recognizes the user.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444604');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444605', '22222222-2222-2222-2222-222222222297', 'What is session tracking?', 'MCQ', 'MEDIUM', '{"options": ["Encrypting all traffic", "Associating requests with one user session", "Compressing images", "Minifying scripts"]}', 'Associating requests with one user session', 'Tracking links stateless requests into one conversation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444605');

-- Web / AJAX (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444606', '22222222-2222-2222-2222-222222222302', 'What does AJAX enable?', 'MCQ', 'MEDIUM', '{"options": ["Full page reloads only", "Partial updates without reloading the page", "Direct database sockets", "Binary browser plugins"]}', 'Partial updates without reloading the page', 'AJAX exchanges data behind the scenes and patches the DOM.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444606');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444607', '22222222-2222-2222-2222-222222222302', 'Which API performs modern AJAX calls?', 'MCQ', 'MEDIUM', '{"options": ["XMLHttpRequest only", "document.write", "fetch", "window.prompt"]}', 'fetch', 'fetch offers promise-based requests over classic XMLHttpRequest.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444607');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444608', '22222222-2222-2222-2222-222222222302', 'What data format does AJAX commonly exchange?', 'MCQ', 'MEDIUM', '{"options": ["Java bytecode", "CSS rules", "JSON", "MP3 audio"]}', 'JSON', 'JSON is lightweight, textual, and native to JavaScript.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444608');

-- Web / Components and Props (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444609', '22222222-2222-2222-2222-222222222304', 'How does data flow with React props?', 'MCQ', 'MEDIUM', '{"options": ["Top-down from parent to child", "Child to parent only", "Bidirectionally by default", "Through the database"]}', 'Top-down from parent to child', 'Props flow one way down; state lifts up explicitly.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444609');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444610', '22222222-2222-2222-2222-222222222304', 'Why are keys needed in React lists?', 'MCQ', 'MEDIUM', '{"options": ["For styling colors", "To sort alphabetically", "To enable cookies", "To help React identify changed items"]}', 'To help React identify changed items', 'Stable keys let reconciliation match elements across renders.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444610');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444611', '22222222-2222-2222-2222-222222222304', 'What is component composition?', 'MCQ', 'MEDIUM', '{"options": ["Copying files", "Building UI by nesting smaller components", "Minifying bundles", "Server rendering only"]}', 'Building UI by nesting smaller components', 'Composition builds complex UI from simple reusable pieces.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444611');

-- AI-ML / Heuristic Search (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444612', '22222222-2222-2222-2222-222222222308', 'What is a heuristic function?', 'MCQ', 'MEDIUM', '{"options": ["The exact path taken", "A random number", "An estimate of remaining cost to the goal", "The start state"]}', 'An estimate of remaining cost to the goal', 'Heuristics guide search by guessing distance cheaply.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444612');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444613', '22222222-2222-2222-2222-222222222308', 'What makes A star search optimal?', 'MCQ', 'MEDIUM', '{"options": ["Greedy speed alone", "Admissible heuristic never overestimating", "Random restarts", "Depth limits"]}', 'Admissible heuristic never overestimating', 'Admissibility keeps the first goal found optimal.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444613');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444614', '22222222-2222-2222-2222-222222222308', 'What does admissibility require?', 'MCQ', 'MEDIUM', '{"options": ["Expanding most nodes first", "Ignoring the goal test", "Avoiding best-first order", "h(n) never exceeds true cost"]}', 'h(n) never exceeds true cost', 'Optimistic estimates preserve optimality guarantees.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444614');

-- AI-ML / Bayesian Networks (HARD)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444615', '22222222-2222-2222-2222-222222222314', 'What does a missing edge encode in a Bayesian network?', 'MCQ', 'HARD', '{"options": ["Direct causation always", "Conditional independence given parents", "Equal probabilities", "A modeling error"]}', 'Conditional independence given parents', 'Graph structure declares which independencies hold.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444615');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444616', '22222222-2222-2222-2222-222222222314', 'What labels each Bayesian network node?', 'MCQ', 'HARD', '{"options": ["A routing table", "A conditional probability table given its parents", "A motor command", "A pixel buffer"]}', 'A conditional probability table given its parents', 'CPTs quantify each variable conditioned on its parents.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444616');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444617', '22222222-2222-2222-2222-222222222314', 'What makes exact inference hard in large networks?', 'MCQ', 'HARD', '{"options": ["Too few variables", "Missing priors in all cases", "Exponential blowup in the worst case", "Small graph size"]}', 'Exponential blowup in the worst case', 'Inference is exponential in treewidth, motivating approximation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444617');

-- AI-ML / Decision Trees (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444618', '22222222-2222-2222-2222-222222222319', 'How is a decision tree split chosen?', 'MCQ', 'MEDIUM', '{"options": ["By alphabetical order", "By reducing impurity such as entropy", "By row count parity", "By random choice always"]}', 'By reducing impurity such as entropy', 'Splits maximize information gain or Gini improvement.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444618');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444619', '22222222-2222-2222-2222-222222222319', 'What is tree pruning?', 'MCQ', 'MEDIUM', '{"options": ["Adding more levels", "Removing branches to reduce overfitting", "Sorting leaves", "Doubling the data"]}', 'Removing branches to reduce overfitting', 'Pruning trades training fit for generalization.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444619');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444620', '22222222-2222-2222-2222-222222222319', 'Which weakness affects deep decision trees?', 'MCQ', 'MEDIUM', '{"options": ["Underfitting always", "Linear speed only", "High variance and overfitting", "Zero training error guaranteed"]}', 'High variance and overfitting', 'Deep trees memorize noise; ensembles and pruning tame them.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444620');

-- AI-ML / K Means Clustering (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444621', '22222222-2222-2222-2222-222222222324', 'What are the two K-means steps?', 'MCQ', 'MEDIUM', '{"options": ["Sort then hash", "Assign points then update centroids", "Split then encrypt", "Sample then stop"]}', 'Assign points then update centroids', 'Lloyd iteration alternates assignment and centroid updates.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444621');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444622', '22222222-2222-2222-2222-222222222324', 'What must be chosen before running K-means?', 'MCQ', 'MEDIUM', '{"options": ["Huffman codes", "Learning rate schedule", "Batch size only", "The number k"]}', 'The number k', 'K-means needs k upfront; elbow or silhouette guides it.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444622');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444623', '22222222-2222-2222-2222-222222222324', 'Which limitation affects K-means?', 'MCQ', 'MEDIUM', '{"options": ["It requires labeled data", "It handles only strings", "Spherical-cluster bias and sensitivity to initialization", "It cannot use distances"]}', 'Spherical-cluster bias and sensitivity to initialization', 'K-means assumes round clusters and depends on starting centroids.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444623');

-- AI-ML / Backpropagation (HARD)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444624', '22222222-2222-2222-2222-222222222328', 'What does backpropagation compute?', 'MCQ', 'HARD', '{"options": ["Activations only", "Loss values only", "Gradients of the loss with respect to weights", "Random directions"]}', 'Gradients of the loss with respect to weights', 'Gradients drive gradient-descent weight updates.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444624');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444625', '22222222-2222-2222-2222-222222222328', 'Which rule carries error backward through layers?', 'MCQ', 'HARD', '{"options": ["Bayes rule", "The chain rule of calculus", "The product rule of sets", "Greedy choice"]}', 'The chain rule of calculus', 'Chained derivatives propagate loss gradients layer by layer.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444625');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444626', '22222222-2222-2222-2222-222222222328', 'What can stop deep networks from learning?', 'MCQ', 'HARD', '{"options": ["Large datasets", "Fast GPUs", "Vanishing or exploding gradients", "Shuffled batches"]}', 'Vanishing or exploding gradients', 'Unstable gradient magnitudes stall or wreck training.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444626');

-- FDS / Data Retrieval and Preparation (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444627', '22222222-2222-2222-2222-222222222332', 'What is data cleaning?', 'MCQ', 'MEDIUM', '{"options": ["Deleting all outliers blindly", "Fixing errors and inconsistencies before analysis", "Encrypting columns", "Sorting file names"]}', 'Fixing errors and inconsistencies before analysis', 'Cleaning repairs values, types and duplicates analysts can trust.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444627');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444628', '22222222-2222-2222-2222-222222222332', 'Which issue does preparation address?', 'MCQ', 'MEDIUM', '{"options": ["GPU shortages", "Slow networks", "Missing values and inconsistent formats", "License costs"]}', 'Missing values and inconsistent formats', 'Preparation standardizes the messy reality of raw data.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444628');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444629', '22222222-2222-2222-2222-222222222332', 'What is a feature in data science?', 'MCQ', 'MEDIUM', '{"options": ["A file extension", "A chart color", "A server log", "A measured attribute used for analysis"]}', 'A measured attribute used for analysis', 'Features are the input columns models learn from.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444629');

-- FDS / Correlation Scatter Plots and Regression (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444630', '22222222-2222-2222-2222-222222222339', 'What does Pearson r equal to 1 mean?', 'MCQ', 'MEDIUM', '{"options": ["No relationship", "Perfect positive linear relationship", "Perfect curve fit", "Causation proven"]}', 'Perfect positive linear relationship', 'Plus one is the ceiling of positive linear association.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444630');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444631', '22222222-2222-2222-2222-222222222339', 'What does a scatter plot show?', 'MCQ', 'MEDIUM', '{"options": ["One mean value", "File sizes", "Joint values of two variables", "Class counts only"]}', 'Joint values of two variables', 'Each point pairs two measurements to reveal relationships.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444631');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444632', '22222222-2222-2222-2222-222222222339', 'What does correlation NOT imply?', 'MCQ', 'MEDIUM', '{"options": ["Association strength", "Linear direction", "Causation", "Variable pairing"]}', 'Causation', 'Correlation measures co-movement, never mechanism.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444632');

-- FDS / Aggregation Grouping and Pivot Tables (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444633', '22222222-2222-2222-2222-222222222345', 'What does split-apply-combine do?', 'MCQ', 'MEDIUM', '{"options": ["Sorts columns alphabetically", "Splits rows into groups, aggregates, then combines", "Deletes duplicates only", "Reshapes images"]}', 'Splits rows into groups, aggregates, then combines', 'Groupby pipelines partition, summarize and reassemble data.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444633');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444634', '22222222-2222-2222-2222-222222222345', 'What is a pivot table?', 'MCQ', 'MEDIUM', '{"options": ["A cross-tabulation summarizing values by categories", "A 3D game engine", "A join key index", "A missing-value filler"]}', 'A cross-tabulation summarizing values by categories', 'Pivots reshape long data into readable summary grids.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444634');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444635', '22222222-2222-2222-2222-222222222345', 'Which aggregation suits skewed income data?', 'MCQ', 'MEDIUM', '{"options": ["Mean always", "Median as robust center", "Mode of names", "Maximum only"]}', 'Median as robust center', 'Medians resist outliers that drag means upward.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444635');

-- FDS / Seaborn (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444636', '22222222-2222-2222-2222-222222222347', 'What is Seaborn built on?', 'MCQ', 'MEDIUM', '{"options": ["D3.js", "Matplotlib", "SQL", "Excel macros"]}', 'Matplotlib', 'Seaborn wraps Matplotlib with statistical defaults.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444636');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444637', '22222222-2222-2222-2222-222222222347', 'What does the hue encoding show?', 'MCQ', 'MEDIUM', '{"options": ["A file path", "Axis limits", "A third variable by color", "Font size"]}', 'A third variable by color', 'Hue splits one plot into colored subgroups.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444637');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444638', '22222222-2222-2222-2222-222222222347', 'When is a regression plot useful?', 'MCQ', 'MEDIUM', '{"options": ["Listing raw tables", "Printing source code", "Counting data files", "Showing fitted trend with uncertainty"]}', 'Showing fitted trend with uncertainty', 'Regplots overlay model fits with confidence bands.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444638');

-- DAA / Asymptotic Analysis (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444639', '22222222-2222-2222-2222-222222222350', 'What does Big-O notation describe?', 'MCQ', 'MEDIUM', '{"options": ["Exact step counts", "An upper bound on growth", "Memory addresses", "Best-case luck"]}', 'An upper bound on growth', 'Big-O bounds worst-case growth up to constants.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444639');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444640', '22222222-2222-2222-2222-222222222350', 'Which function grows fastest?', 'MCQ', 'MEDIUM', '{"options": ["O(n)", "O(n log n)", "O(n squared)", "O(log n)"]}', 'O(n squared)', 'Quadratic growth outruns linearithmic and linear rates.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444640');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444641', '22222222-2222-2222-2222-222222222350', 'What does Theta notation give?', 'MCQ', 'MEDIUM', '{"options": ["Only an upper bound", "A tight bound above and below", "Only a lower bound", "No bound at all"]}', 'A tight bound above and below', 'Theta sandwiches growth between matching bounds.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444641');

-- DAA / Knuth Morris Pratt Algorithm (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444642', '22222222-2222-2222-2222-222222222355', 'What does the KMP prefix function encode?', 'MCQ', 'MEDIUM', '{"options": ["Alphabet size", "Longest proper prefix that is also a suffix", "Text length", "Hash collision counts"]}', 'Longest proper prefix that is also a suffix', 'The table tells how far to fall back on mismatch.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444642');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444643', '22222222-2222-2222-2222-222222222355', 'Why does KMP run in linear time?', 'MCQ', 'MEDIUM', '{"options": ["It sorts the text first", "It hashes everything", "It uses extra threads", "It never re-examines text characters wastefully"]}', 'It never re-examines text characters wastefully', 'Each text character advances the scan at most once.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444643');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444644', '22222222-2222-2222-2222-222222222355', 'What triggers a KMP fallback?', 'MCQ', 'MEDIUM', '{"options": ["End of input", "A mismatch after partial match", "Any vowel", "Timeout only"]}', 'A mismatch after partial match', 'Fallback reuses the matched prefix instead of restarting.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444644');

-- DAA / Merge Sort and Quick Sort (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444645', '22222222-2222-2222-2222-222222222359', 'What is the average case of quicksort?', 'MCQ', 'MEDIUM', '{"options": ["Theta(n squared)", "Theta(n log n)", "Theta(n)", "Theta(log n)"]}', 'Theta(n log n)', 'Random pivots split evenly on average.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444645');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444646', '22222222-2222-2222-2222-222222222359', 'What does partitioning produce?', 'MCQ', 'MEDIUM', '{"options": ["Two sorted halves", "Elements split around a pivot", "One merged run", "A heap"]}', 'Elements split around a pivot', 'Partition places smaller left and larger right of the pivot.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444646');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444647', '22222222-2222-2222-2222-222222222359', 'What is the worst case of quicksort?', 'MCQ', 'MEDIUM', '{"options": ["Already balanced input", "Random pivots", "Theta(n squared) on bad pivots", "Constant time"]}', 'Theta(n squared) on bad pivots', 'Degenerate pivots recurse on nearly the whole array.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444647');

-- DAA / Matrix Chain Multiplication (HARD)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444648', '22222222-2222-2222-2222-222222222365', 'What is optimized in matrix-chain multiplication?', 'MCQ', 'HARD', '{"options": ["The numeric entries", "The parenthesization order", "The matrix shapes", "The data type"]}', 'The parenthesization order', 'Bracketing decides the scalar multiplication count.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444648');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444649', '22222222-2222-2222-2222-222222222365', 'Why does multiplication order matter?', 'MCQ', 'HARD', '{"options": ["It changes the result matrix", "It affects numerical stability only", "Multiplication counts differ by parenthesization", "It changes matrix dimensions"]}', 'Multiplication counts differ by parenthesization', 'Dimensions make some bracketings vastly cheaper.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444649');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444650', '22222222-2222-2222-2222-222222222365', 'What recurrence structure applies?', 'MCQ', 'HARD', '{"options": ["Greedy choice", "Divide without overlap", "Optimal substructure over split positions", "Brute force only"]}', 'Optimal substructure over split positions', 'Best cost splits at some k with optimal subchains.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444650');

-- DAA / Prim and Kruskal Algorithms (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444651', '22222222-2222-2222-2222-222222222367', 'What do Prim and Kruskal build?', 'MCQ', 'MEDIUM', '{"options": ["Shortest paths", "Minimum spanning trees", "Max flows", "Topological orders"]}', 'Minimum spanning trees', 'Both grow cheapest edge sets connecting all vertices.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444651');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444652', '22222222-2222-2222-2222-222222222367', 'How does Kruskal proceed?', 'MCQ', 'MEDIUM', '{"options": ["Grows one tree from a start root", "Relaxes all edges repeatedly", "Adds cheapest safe edges using union-find", "Augments flow paths"]}', 'Adds cheapest safe edges using union-find', 'Sorted edges join components unless they form cycles.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444652');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444653', '22222222-2222-2222-2222-222222222367', 'What is union-find for?', 'MCQ', 'MEDIUM', '{"options": ["Sorting edges", "Tracking connectivity components", "Hashing vertices", "Timing runs"]}', 'Tracking connectivity components', 'Find-union tests cycles in almost constant time.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444653');

-- DAA / Backtracking and N Queens (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444654', '22222222-2222-2222-2222-222222222374', 'What is backtracking?', 'MCQ', 'MEDIUM', '{"options": ["Sorting inputs first", "Trying partial solutions and undoing dead ends", "Greedy committing forever", "Random restarts only"]}', 'Trying partial solutions and undoing dead ends', 'Search retreats from violated constraints to try alternatives.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444654');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444655', '22222222-2222-2222-2222-222222222374', 'What constraint defines N-Queens?', 'MCQ', 'MEDIUM', '{"options": ["Queens move like knights", "The board must be full", "Queens share colors", "No two queens share row, column or diagonal"]}', 'No two queens share row, column or diagonal', 'One queen per row, column and diagonal solves it.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444655');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444656', '22222222-2222-2222-2222-222222222374', 'When does backtracking prune?', 'MCQ', 'MEDIUM', '{"options": ["At depth limits only", "When a partial solution already violates constraints", "Never during search", "Only at the root"]}', 'When a partial solution already violates constraints', 'Early pruning skips entire hopeless subtrees.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444656');

-- ------------------------------------------------------------------
-- 2) Quizzes (29): 1 CURATED quiz per round-2 topic, same topic order
-- ------------------------------------------------------------------
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555573', '22222222-2222-2222-2222-222222222245', 'Data Types Challenge', 'Apply primitive types, defaults and conversions.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555573');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555574', '22222222-2222-2222-2222-222222222250', 'Constructors Challenge', 'Build objects through constructor rules and chaining.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555574');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555575', '22222222-2222-2222-2222-222222222256', 'Interfaces Challenge', 'Design with contracts and functional interfaces.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555575');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555576', '22222222-2222-2222-2222-222222222260', 'Collections Challenge', 'Choose structures, hash wisely and type safely.', 'HARD', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555576');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555577', '22222222-2222-2222-2222-222222222265', 'Requirements Challenge', 'Separate functional needs from quality constraints.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555577');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555578', '22222222-2222-2222-2222-222222222269', 'UML Relationships Challenge', 'Read aggregation, generalization and dependencies.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555578');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555579', '22222222-2222-2222-2222-222222222273', 'Components Challenge', 'Model replaceable parts and their interfaces.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555579');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555580', '22222222-2222-2222-2222-222222222275', 'Sequences Challenge', 'Trace lifelines, messages and fragments.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555580');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555581', '22222222-2222-2222-2222-222222222281', 'Patterns Challenge', 'Apply Singleton, Observer and Strategy.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555581');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555582', '22222222-2222-2222-2222-222222222289', 'CSS Challenge', 'Target elements and mind the box model.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555582');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555583', '22222222-2222-2222-2222-222222222293', 'DOM Challenge', 'Select, create and attach document nodes.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555583');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555584', '22222222-2222-2222-2222-222222222297', 'Sessions Challenge', 'Track users across stateless requests.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555584');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555585', '22222222-2222-2222-2222-222222222302', 'AJAX Challenge', 'Fetch data and patch pages without reloads.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555585');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555586', '22222222-2222-2222-2222-222222222304', 'Props Challenge', 'Pass data down and compose components.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555586');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555587', '22222222-2222-2222-2222-222222222308', 'Heuristics Challenge', 'Estimate cost and keep A star admissible.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555587');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555588', '22222222-2222-2222-2222-222222222314', 'Bayes Nets Challenge', 'Read independence from graph structure.', 'HARD', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555588');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555589', '22222222-2222-2222-2222-222222222319', 'Trees Challenge', 'Split by impurity and prune wisely.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555589');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555590', '22222222-2222-2222-2222-222222222324', 'K-Means Challenge', 'Assign, update and choose k carefully.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555590');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555591', '22222222-2222-2222-2222-222222222328', 'Backprop Challenge', 'Push gradients back through layers.', 'HARD', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555591');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555592', '22222222-2222-2222-2222-222222222332', 'Preparation Challenge', 'Clean values and engineer features.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555592');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555593', '22222222-2222-2222-2222-222222222339', 'Correlation Challenge', 'Read scatter and respect causation limits.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555593');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555594', '22222222-2222-2222-2222-222222222345', 'Aggregation Challenge', 'Group, summarize and pivot with care.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555594');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555595', '22222222-2222-2222-2222-222222222347', 'Seaborn Challenge', 'Encode variables and fit trends.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555595');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555596', '22222222-2222-2222-2222-222222222350', 'Asymptotics Challenge', 'Bound growth above and below.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555596');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555597', '22222222-2222-2222-2222-222222222355', 'KMP Challenge', 'Fall back with the prefix function.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555597');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555598', '22222222-2222-2222-2222-222222222359', 'Quicksort Challenge', 'Partition around pivots, mind the worst case.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555598');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555599', '22222222-2222-2222-2222-222222222365', 'Matrix Chain Challenge', 'Parenthesize for the cheapest order.', 'HARD', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555599');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555600', '22222222-2222-2222-2222-222222222367', 'MST Challenge', 'Grow cheapest safe edge sets.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555600');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555601', '22222222-2222-2222-2222-222222222374', 'Backtracking Challenge', 'Prune early on violated constraints.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555601');

-- ------------------------------------------------------------------
-- 3) QuizQuestions (87): 3 same-topic links per quiz, ordered 1..3
-- ------------------------------------------------------------------
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666748', '55555555-5555-5555-5555-555555555573', '44444444-4444-4444-4444-444444444570', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666748');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666749', '55555555-5555-5555-5555-555555555573', '44444444-4444-4444-4444-444444444571', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666749');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666750', '55555555-5555-5555-5555-555555555573', '44444444-4444-4444-4444-444444444572', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666750');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666751', '55555555-5555-5555-5555-555555555574', '44444444-4444-4444-4444-444444444573', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666751');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666752', '55555555-5555-5555-5555-555555555574', '44444444-4444-4444-4444-444444444574', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666752');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666753', '55555555-5555-5555-5555-555555555574', '44444444-4444-4444-4444-444444444575', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666753');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666754', '55555555-5555-5555-5555-555555555575', '44444444-4444-4444-4444-444444444576', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666754');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666755', '55555555-5555-5555-5555-555555555575', '44444444-4444-4444-4444-444444444577', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666755');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666756', '55555555-5555-5555-5555-555555555575', '44444444-4444-4444-4444-444444444578', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666756');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666757', '55555555-5555-5555-5555-555555555576', '44444444-4444-4444-4444-444444444579', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666757');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666758', '55555555-5555-5555-5555-555555555576', '44444444-4444-4444-4444-444444444580', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666758');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666759', '55555555-5555-5555-5555-555555555576', '44444444-4444-4444-4444-444444444581', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666759');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666760', '55555555-5555-5555-5555-555555555577', '44444444-4444-4444-4444-444444444582', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666760');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666761', '55555555-5555-5555-5555-555555555577', '44444444-4444-4444-4444-444444444583', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666761');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666762', '55555555-5555-5555-5555-555555555577', '44444444-4444-4444-4444-444444444584', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666762');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666763', '55555555-5555-5555-5555-555555555578', '44444444-4444-4444-4444-444444444585', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666763');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666764', '55555555-5555-5555-5555-555555555578', '44444444-4444-4444-4444-444444444586', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666764');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666765', '55555555-5555-5555-5555-555555555578', '44444444-4444-4444-4444-444444444587', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666765');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666766', '55555555-5555-5555-5555-555555555579', '44444444-4444-4444-4444-444444444588', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666766');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666767', '55555555-5555-5555-5555-555555555579', '44444444-4444-4444-4444-444444444589', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666767');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666768', '55555555-5555-5555-5555-555555555579', '44444444-4444-4444-4444-444444444590', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666768');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666769', '55555555-5555-5555-5555-555555555580', '44444444-4444-4444-4444-444444444591', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666769');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666770', '55555555-5555-5555-5555-555555555580', '44444444-4444-4444-4444-444444444592', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666770');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666771', '55555555-5555-5555-5555-555555555580', '44444444-4444-4444-4444-444444444593', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666771');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666772', '55555555-5555-5555-5555-555555555581', '44444444-4444-4444-4444-444444444594', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666772');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666773', '55555555-5555-5555-5555-555555555581', '44444444-4444-4444-4444-444444444595', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666773');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666774', '55555555-5555-5555-5555-555555555581', '44444444-4444-4444-4444-444444444596', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666774');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666775', '55555555-5555-5555-5555-555555555582', '44444444-4444-4444-4444-444444444597', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666775');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666776', '55555555-5555-5555-5555-555555555582', '44444444-4444-4444-4444-444444444598', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666776');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666777', '55555555-5555-5555-5555-555555555582', '44444444-4444-4444-4444-444444444599', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666777');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666778', '55555555-5555-5555-5555-555555555583', '44444444-4444-4444-4444-444444444600', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666778');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666779', '55555555-5555-5555-5555-555555555583', '44444444-4444-4444-4444-444444444601', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666779');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666780', '55555555-5555-5555-5555-555555555583', '44444444-4444-4444-4444-444444444602', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666780');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666781', '55555555-5555-5555-5555-555555555584', '44444444-4444-4444-4444-444444444603', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666781');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666782', '55555555-5555-5555-5555-555555555584', '44444444-4444-4444-4444-444444444604', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666782');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666783', '55555555-5555-5555-5555-555555555584', '44444444-4444-4444-4444-444444444605', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666783');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666784', '55555555-5555-5555-5555-555555555585', '44444444-4444-4444-4444-444444444606', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666784');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666785', '55555555-5555-5555-5555-555555555585', '44444444-4444-4444-4444-444444444607', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666785');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666786', '55555555-5555-5555-5555-555555555585', '44444444-4444-4444-4444-444444444608', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666786');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666787', '55555555-5555-5555-5555-555555555586', '44444444-4444-4444-4444-444444444609', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666787');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666788', '55555555-5555-5555-5555-555555555586', '44444444-4444-4444-4444-444444444610', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666788');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666789', '55555555-5555-5555-5555-555555555586', '44444444-4444-4444-4444-444444444611', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666789');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666790', '55555555-5555-5555-5555-555555555587', '44444444-4444-4444-4444-444444444612', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666790');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666791', '55555555-5555-5555-5555-555555555587', '44444444-4444-4444-4444-444444444613', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666791');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666792', '55555555-5555-5555-5555-555555555587', '44444444-4444-4444-4444-444444444614', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666792');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666793', '55555555-5555-5555-5555-555555555588', '44444444-4444-4444-4444-444444444615', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666793');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666794', '55555555-5555-5555-5555-555555555588', '44444444-4444-4444-4444-444444444616', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666794');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666795', '55555555-5555-5555-5555-555555555588', '44444444-4444-4444-4444-444444444617', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666795');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666796', '55555555-5555-5555-5555-555555555589', '44444444-4444-4444-4444-444444444618', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666796');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666797', '55555555-5555-5555-5555-555555555589', '44444444-4444-4444-4444-444444444619', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666797');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666798', '55555555-5555-5555-5555-555555555589', '44444444-4444-4444-4444-444444444620', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666798');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666799', '55555555-5555-5555-5555-555555555590', '44444444-4444-4444-4444-444444444621', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666799');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666800', '55555555-5555-5555-5555-555555555590', '44444444-4444-4444-4444-444444444622', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666800');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666801', '55555555-5555-5555-5555-555555555590', '44444444-4444-4444-4444-444444444623', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666801');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666802', '55555555-5555-5555-5555-555555555591', '44444444-4444-4444-4444-444444444624', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666802');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666803', '55555555-5555-5555-5555-555555555591', '44444444-4444-4444-4444-444444444625', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666803');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666804', '55555555-5555-5555-5555-555555555591', '44444444-4444-4444-4444-444444444626', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666804');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666805', '55555555-5555-5555-5555-555555555592', '44444444-4444-4444-4444-444444444627', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666805');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666806', '55555555-5555-5555-5555-555555555592', '44444444-4444-4444-4444-444444444628', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666806');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666807', '55555555-5555-5555-5555-555555555592', '44444444-4444-4444-4444-444444444629', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666807');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666808', '55555555-5555-5555-5555-555555555593', '44444444-4444-4444-4444-444444444630', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666808');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666809', '55555555-5555-5555-5555-555555555593', '44444444-4444-4444-4444-444444444631', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666809');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666810', '55555555-5555-5555-5555-555555555593', '44444444-4444-4444-4444-444444444632', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666810');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666811', '55555555-5555-5555-5555-555555555594', '44444444-4444-4444-4444-444444444633', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666811');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666812', '55555555-5555-5555-5555-555555555594', '44444444-4444-4444-4444-444444444634', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666812');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666813', '55555555-5555-5555-5555-555555555594', '44444444-4444-4444-4444-444444444635', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666813');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666814', '55555555-5555-5555-5555-555555555595', '44444444-4444-4444-4444-444444444636', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666814');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666815', '55555555-5555-5555-5555-555555555595', '44444444-4444-4444-4444-444444444637', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666815');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666816', '55555555-5555-5555-5555-555555555595', '44444444-4444-4444-4444-444444444638', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666816');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666817', '55555555-5555-5555-5555-555555555596', '44444444-4444-4444-4444-444444444639', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666817');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666818', '55555555-5555-5555-5555-555555555596', '44444444-4444-4444-4444-444444444640', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666818');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666819', '55555555-5555-5555-5555-555555555596', '44444444-4444-4444-4444-444444444641', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666819');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666820', '55555555-5555-5555-5555-555555555597', '44444444-4444-4444-4444-444444444642', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666820');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666821', '55555555-5555-5555-5555-555555555597', '44444444-4444-4444-4444-444444444643', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666821');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666822', '55555555-5555-5555-5555-555555555597', '44444444-4444-4444-4444-444444444644', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666822');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666823', '55555555-5555-5555-5555-555555555598', '44444444-4444-4444-4444-444444444645', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666823');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666824', '55555555-5555-5555-5555-555555555598', '44444444-4444-4444-4444-444444444646', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666824');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666825', '55555555-5555-5555-5555-555555555598', '44444444-4444-4444-4444-444444444647', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666825');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666826', '55555555-5555-5555-5555-555555555599', '44444444-4444-4444-4444-444444444648', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666826');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666827', '55555555-5555-5555-5555-555555555599', '44444444-4444-4444-4444-444444444649', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666827');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666828', '55555555-5555-5555-5555-555555555599', '44444444-4444-4444-4444-444444444650', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666828');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666829', '55555555-5555-5555-5555-555555555600', '44444444-4444-4444-4444-444444444651', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666829');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666830', '55555555-5555-5555-5555-555555555600', '44444444-4444-4444-4444-444444444652', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666830');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666831', '55555555-5555-5555-5555-555555555600', '44444444-4444-4444-4444-444444444653', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666831');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666832', '55555555-5555-5555-5555-555555555601', '44444444-4444-4444-4444-444444444654', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666832');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666833', '55555555-5555-5555-5555-555555555601', '44444444-4444-4444-4444-444444444655', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666833');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666834', '55555555-5555-5555-5555-555555555601', '44444444-4444-4444-4444-444444444656', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666834');
