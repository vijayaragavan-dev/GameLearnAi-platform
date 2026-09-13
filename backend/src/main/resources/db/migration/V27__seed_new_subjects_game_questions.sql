-- GameLearn AI - Batch 2 / Phase 4: playable question content for the 6 new subjects.
-- Seeds real, syllabus-aligned MCQ content on one representative topic per
-- new unit (29 topics x 3 questions = 87 questions), plus one CURATED quiz
-- per topic (29 quizzes) with deterministic quiz_question links.
-- Deterministic reserved namespaces continuing the existing blocks:
--   questions      : 44444444-...-483..569 (87)
--   quizzes        : 55555555-...-544..572 (29)
--   quiz_questions : 66666666-...-661..747 (87)
-- Every statement is INSERT...SELECT...WHERE NOT EXISTS (H2 + MySQL
-- portable): re-running never duplicates. Additive only: existing V12/V14
-- content is untouched. Correct answers always equal one of the options
-- (positions vary, never implicitly options[0]).

-- ------------------------------------------------------------------
-- 1) Questions (87): 3 per topic, one representative topic per new unit
-- ------------------------------------------------------------------

-- OOP / Java Platform and Program Structure (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444483', '22222222-2222-2222-2222-222222222244', 'Which component executes Java bytecode?', 'MCQ', 'EASY', '{"options": ["Java Virtual Machine (JVM)", "Java compiler (javac)", "Java documentation tool", "Java archiver"]}', 'Java Virtual Machine (JVM)', 'The JVM executes bytecode on each platform; javac only compiles source to bytecode.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444483');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444484', '22222222-2222-2222-2222-222222222244', 'Which method is the entry point of a Java application?', 'MCQ', 'EASY', '{"options": ["public void start()", "public static void main(String[] args)", "static int main()", "void init()"]}', 'public static void main(String[] args)', 'The JVM looks for the exact main signature to start the program.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444484');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444485', '22222222-2222-2222-2222-222222222244', 'What does the JDK include that the JRE alone does not?', 'MCQ', 'EASY', '{"options": ["The virtual machine", "The class libraries", "Development tools such as the compiler", "The garbage collector"]}', 'Development tools such as the compiler', 'The JDK bundles the JRE plus development tools like javac.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444485');

-- OOP / Classes and Objects (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444486', '22222222-2222-2222-2222-222222222249', 'What is an object in Java?', 'MCQ', 'EASY', '{"options": ["An instance of a class holding state and behavior", "A primitive data type", "A package of classes", "A compiled bytecode file"]}', 'An instance of a class holding state and behavior', 'Objects are class instances with fields (state) and methods (behavior).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444486');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444487', '22222222-2222-2222-2222-222222222249', 'Which keyword creates a new object?', 'MCQ', 'EASY', '{"options": ["create", "alloc", "new", "instance"]}', 'new', 'The new keyword allocates the object and invokes its constructor.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444487');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444488', '22222222-2222-2222-2222-222222222249', 'Where are Java objects stored in memory?', 'MCQ', 'EASY', '{"options": ["On the stack", "In registers", "In source files", "On the heap"]}', 'On the heap', 'Objects live on the heap and are reclaimed by the garbage collector.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444488');

-- OOP / Inheritance (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444489', '22222222-2222-2222-2222-222222222253', 'Which keyword establishes inheritance between classes?', 'MCQ', 'MEDIUM', '{"options": ["extends", "inherits", "super", "implements"]}', 'extends', 'A class extends its parent; implements is reserved for interfaces.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444489');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444490', '22222222-2222-2222-2222-222222222253', 'What does a super() call invoke?', 'MCQ', 'MEDIUM', '{"options": ["The current method", "A static method", "The parent class constructor", "The subclass constructor"]}', 'The parent class constructor', 'super() must be the first statement and chains to the parent constructor.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444490');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444491', '22222222-2222-2222-2222-222222222253', 'Which statement about method overriding is true?', 'MCQ', 'MEDIUM', '{"options": ["The method must be static", "The method must be private", "Overriding requires a different method name", "The subclass provides its own implementation of an inherited method"]}', 'The subclass provides its own implementation of an inherited method', 'Overriding keeps the signature and replaces the inherited behavior.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444491');

-- OOP / Exception Handling (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444492', '22222222-2222-2222-2222-222222222258', 'Which block always executes after try and catch?', 'MCQ', 'MEDIUM', '{"options": ["finally", "final", "finalize", "catch-all"]}', 'finally', 'finally runs for cleanup whether or not an exception occurred.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444492');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444493', '22222222-2222-2222-2222-222222222258', 'Which keyword declares that a method may throw an exception?', 'MCQ', 'MEDIUM', '{"options": ["throw", "try", "throws", "catch"]}', 'throws', 'throws is part of the method signature; throw raises a specific instance.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444493');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444494', '22222222-2222-2222-2222-222222222258', 'What is the root of the Java exception hierarchy?', 'MCQ', 'MEDIUM', '{"options": ["Exception", "Error", "RuntimeException", "Throwable"]}', 'Throwable', 'Throwable is the root; Exception and Error both extend it.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444494');

-- OOSE / Software Engineering and Process Models (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444495', '22222222-2222-2222-2222-222222222264', 'Which process model proceeds through phases without going back?', 'MCQ', 'EASY', '{"options": ["Waterfall", "Spiral", "Agile Scrum", "Iterative"]}', 'Waterfall', 'Waterfall flows linearly through requirements to maintenance with no planned return.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444495');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444496', '22222222-2222-2222-2222-222222222264', 'What does SDLC stand for?', 'MCQ', 'EASY', '{"options": ["System Design and Logic Code", "Software Development Life Cycle", "Software Deployment and Launch Control", "Structured Data Lifecycle"]}', 'Software Development Life Cycle', 'SDLC names the end-to-end phases software passes through.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444496');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444497', '22222222-2222-2222-2222-222222222264', 'Which approach delivers working software in short sprints?', 'MCQ', 'EASY', '{"options": ["Waterfall", "V-model", "Agile Scrum", "Big bang"]}', 'Agile Scrum', 'Scrum organizes work into short inspect-and-adapt sprints.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444497');

-- OOSE / Object Oriented Analysis and Design (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444498', '22222222-2222-2222-2222-222222222267', 'What is the main goal of object-oriented analysis?', 'MCQ', 'MEDIUM', '{"options": ["To model the problem domain with objects and responsibilities", "To write code as fast as possible", "To design the database schema first", "To draw deployment diagrams"]}', 'To model the problem domain with objects and responsibilities', 'Analysis builds an object model of the problem before design decisions.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444498');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444499', '22222222-2222-2222-2222-222222222267', 'Which activity comes first in OOAD?', 'MCQ', 'MEDIUM', '{"options": ["Implementation", "Analysis of requirements", "Testing", "Deployment"]}', 'Analysis of requirements', 'OOAD starts by analyzing requirements into candidate objects.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444499');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444500', '22222222-2222-2222-2222-222222222267', 'What is a responsibility in OOAD?', 'MCQ', 'MEDIUM', '{"options": ["A Java package", "A test case", "A duty assigned to an object: knowing or doing", "A sprint backlog item"]}', 'A duty assigned to an object: knowing or doing', 'Responsibility-driven design assigns knowing and doing duties to objects.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444500');

-- OOSE / Class Diagrams (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444501', '22222222-2222-2222-2222-222222222270', 'What does a class diagram show?', 'MCQ', 'MEDIUM', '{"options": ["Classes with attributes, operations and relationships", "Object memory addresses", "Runtime message order", "Deployment servers"]}', 'Classes with attributes, operations and relationships', 'Class diagrams capture static structure: classes plus their links.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444501');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444502', '22222222-2222-2222-2222-222222222270', 'What does the multiplicity 1..* mean?', 'MCQ', 'MEDIUM', '{"options": ["Zero or one instance", "Exactly one instance", "One or more instances", "Many to many always"]}', 'One or more instances', 'The lower bound 1 requires at least one linked instance.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444502');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444503', '22222222-2222-2222-2222-222222222270', 'Which UML relationship expresses the strongest whole-part ownership?', 'MCQ', 'MEDIUM', '{"options": ["Association", "Dependency", "Generalization", "Composition"]}', 'Composition', 'Composition owns its parts: destroying the whole destroys the parts.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444503');

-- OOSE / Use Case Diagrams (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444504', '22222222-2222-2222-2222-222222222274', 'What is an actor in a use case diagram?', 'MCQ', 'EASY', '{"options": ["An external role interacting with the system", "A Java class", "A test runner", "A database table"]}', 'An external role interacting with the system', 'Actors are external users or systems, not internal classes.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444504');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444505', '22222222-2222-2222-2222-222222222274', 'What does an include relationship mean?', 'MCQ', 'EASY', '{"options": ["Optional behavior at runtime", "A use case always incorporates another use case", "An actor logs in", "A diagram border style"]}', 'A use case always incorporates another use case', 'Include factors out mandatory shared behavior into a reused use case.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444505');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444506', '22222222-2222-2222-2222-222222222274', 'What bounds the scope of the modelled system?', 'MCQ', 'EASY', '{"options": ["The actor icon", "The extend arrow", "The system boundary rectangle", "The package tab"]}', 'The system boundary rectangle', 'Everything inside the boundary is the system; actors stay outside.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444506');

-- OOSE / Domain Modelling (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444507', '22222222-2222-2222-2222-222222222279', 'What is a conceptual class in a domain model?', 'MCQ', 'MEDIUM', '{"options": ["A Java source file", "A database table", "A domain idea, not a software class", "A unit test"]}', 'A domain idea, not a software class', 'Domain models capture real-world concepts before software design.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444507');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444508', '22222222-2222-2222-2222-222222222279', 'Domain models are mainly derived from what?', 'MCQ', 'MEDIUM', '{"options": ["Code comments", "Sprint velocity", "Server logs", "Use cases and requirements"]}', 'Use cases and requirements', 'Noun phrases in use cases reveal candidate conceptual classes.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444508');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444509', '22222222-2222-2222-2222-222222222279', 'Which statement belongs in a domain model?', 'MCQ', 'MEDIUM', '{"options": ["public static void main", "SELECT * FROM users", "Sprint retrospective notes", "Customer places Order"]}', 'Customer places Order', 'Domain models record business facts, never code or SQL.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444509');

-- Web / HTML5 Fundamentals (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444510', '22222222-2222-2222-2222-222222222287', 'What does HTML stand for?', 'MCQ', 'EASY', '{"options": ["HyperText Markup Language", "HighText Machine Language", "Hyperlink Text Model", "Home Tool Markup Language"]}', 'HyperText Markup Language', 'HTML is the markup language that structures web pages.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444510');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444511', '22222222-2222-2222-2222-222222222287', 'Which tag defines the largest heading?', 'MCQ', 'EASY', '{"options": ["<h6>", "<head>", "<h1>", "<header>"]}', '<h1>', 'Heading levels run h1 (largest) to h6 (smallest).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444511');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444512', '22222222-2222-2222-2222-222222222287', 'Which element is semantic HTML5?', 'MCQ', 'EASY', '{"options": ["<div>", "<span>", "<b>", "<article>"]}', '<article>', 'Semantic elements like article describe meaning; div and span carry none.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444512');

-- Web / JavaScript Fundamentals (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444513', '22222222-2222-2222-2222-222222222291', 'Which keyword declares a block-scoped variable in JavaScript?', 'MCQ', 'EASY', '{"options": ["let", "int", "float", "string"]}', 'let', 'let (and const) are block-scoped; int and float are not JS keywords.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444513');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444514', '22222222-2222-2222-2222-222222222291', 'What is the result of typeof [] in JavaScript?', 'MCQ', 'EASY', '{"options": ["array", "list", "object", "undefined"]}', 'object', 'Arrays are objects in JS; Array.isArray performs the real check.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444514');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444515', '22222222-2222-2222-2222-222222222291', 'What does === compare in JavaScript?', 'MCQ', 'EASY', '{"options": ["Value with type conversion", "Only object references", "Only string length", "Value and type without conversion"]}', 'Value and type without conversion', 'Strict equality skips coercion, unlike ==.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444515');

-- Web / Servlets (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444516', '22222222-2222-2222-2222-222222222296', 'Which servlet method handles HTTP GET requests?', 'MCQ', 'MEDIUM', '{"options": ["doGet", "doPost", "serviceGet", "handleGet"]}', 'doGet', 'The container dispatches GET to doGet and POST to doPost.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444516');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444517', '22222222-2222-2222-2222-222222222296', 'What is the servlet lifecycle order?', 'MCQ', 'MEDIUM', '{"options": ["service, init, destroy", "destroy, init, service", "init, service, destroy", "init, destroy, service"]}', 'init, service, destroy', 'The container initializes once, services each request, then destroys.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444517');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444518', '22222222-2222-2222-2222-222222222296', 'Where do Java servlets execute?', 'MCQ', 'MEDIUM', '{"options": ["In the browser", "In the database", "On the GPU", "In a servlet container such as Tomcat"]}', 'In a servlet container such as Tomcat', 'Servlets run server-side inside a container managing their lifecycle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444518');

-- Web / PHP Fundamentals (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444519', '22222222-2222-2222-2222-222222222299', 'Which character starts a PHP variable name?', 'MCQ', 'EASY', '{"options": ["$", "#", "@", "%"]}', '$', 'Every PHP variable begins with a dollar sign.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444519');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444520', '22222222-2222-2222-2222-222222222299', 'Which superglobal holds submitted form POST data?', 'MCQ', 'EASY', '{"options": ["$POST", "$_FORM", "$_POST", "$postData"]}', '$_POST', 'PHP populates $_POST with posted form fields.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444520');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444521', '22222222-2222-2222-2222-222222222299', 'Where do PHP scripts execute?', 'MCQ', 'EASY', '{"options": ["In the browser DOM", "In the CSS engine", "On the server before the page is sent", "On the network router"]}', 'On the server before the page is sent', 'PHP is server-side: it renders output delivered to the browser.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444521');

-- Web / React and JSX (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444522', '22222222-2222-2222-2222-222222222303', 'What is JSX?', 'MCQ', 'MEDIUM', '{"options": ["A syntax extension mixing HTML-like markup with JavaScript", "A database query language", "A CSS preprocessor", "A test framework"]}', 'A syntax extension mixing HTML-like markup with JavaScript', 'JSX compiles to React.createElement calls describing UI.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444522');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444523', '22222222-2222-2222-2222-222222222303', 'What is the virtual DOM in React?', 'MCQ', 'MEDIUM', '{"options": ["The browser window object", "A shadow router", "An in-memory representation React diffs to update efficiently", "A JSX compiler pass"]}', 'An in-memory representation React diffs to update efficiently', 'Diffing minimizes real DOM writes to what actually changed.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444523');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444524', '22222222-2222-2222-2222-222222222303', 'Which code defines a React function component?', 'MCQ', 'MEDIUM', '{"options": ["class Welcome extends Servlet", "SELECT COMPONENT Welcome", "<component>Welcome</component>", "function Welcome(props) returning JSX"]}', 'function Welcome(props) returning JSX', 'Function components are plain functions of props returning JSX.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444524');

-- AI-ML / AI and Problem Solving Agents (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444525', '22222222-2222-2222-2222-222222222306', 'What is an intelligent agent?', 'MCQ', 'EASY', '{"options": ["An entity perceiving its environment and acting on it", "A sorting algorithm", "A database index", "A CSS rule"]}', 'An entity perceiving its environment and acting on it', 'Agents close the loop from sensors through decisions to actuators.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444525');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444526', '22222222-2222-2222-2222-222222222306', 'What does PEAS specify for an agent design?', 'MCQ', 'EASY', '{"options": ["Program, Export, Analyze, Save", "Performance, Environment, Actuators, Sensors", "Perceptron, Error, Activation, Synapse", "Plan, Execute, Assert, Stop"]}', 'Performance, Environment, Actuators, Sensors', 'PEAS frames what the agent optimizes, senses and affects.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444526');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444527', '22222222-2222-2222-2222-222222222306', 'Which agent acts on condition-action rules from the current percept?', 'MCQ', 'EASY', '{"options": ["Utility agent", "Learning agent", "Goal agent", "Simple reflex agent"]}', 'Simple reflex agent', 'Simple reflex agents map the current percept directly to an action.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444527');

-- AI-ML / Bayesian Inference (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444528', '22222222-2222-2222-2222-222222222312', 'What does Bayes rule compute?', 'MCQ', 'MEDIUM', '{"options": ["Posterior probability from prior and likelihood", "The shortest path in a graph", "The maximum flow value", "The gradient magnitude"]}', 'Posterior probability from prior and likelihood', 'Bayes rule updates beliefs by combining prior with observed evidence.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444528');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444529', '22222222-2222-2222-2222-222222222312', 'What is a prior in Bayesian reasoning?', 'MCQ', 'MEDIUM', '{"options": ["The final answer", "A search heuristic", "Belief before seeing evidence", "A loss value"]}', 'Belief before seeing evidence', 'The prior seeds inference and the posterior refines it with data.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444529');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444530', '22222222-2222-2222-2222-222222222312', 'The posterior is proportional to what?', 'MCQ', 'MEDIUM', '{"options": ["Prior minus likelihood", "Likelihood divided by error", "Evidence alone", "Likelihood times prior"]}', 'Likelihood times prior', 'Posterior scales with likelihood times prior, normalized by evidence.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444530');

-- AI-ML / Linear Regression (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444531', '22222222-2222-2222-2222-222222222316', 'What does linear regression predict?', 'MCQ', 'EASY', '{"options": ["A continuous numeric value", "A class label only", "A cluster identifier", "A parse tree"]}', 'A continuous numeric value', 'Regression maps inputs to continuous targets like price or temperature.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444531');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444532', '22222222-2222-2222-2222-222222222316', 'Which cost function is minimized in basic linear regression?', 'MCQ', 'EASY', '{"options": ["Cross entropy", "Mean squared error", "Hinge loss", "Zero-one loss"]}', 'Mean squared error', 'MSE penalizes squared residuals and yields the least-squares fit.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444532');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444533', '22222222-2222-2222-2222-222222222316', 'What is overfitting?', 'MCQ', 'EASY', '{"options": ["Under-training a model", "Missing input values", "Fitting noise so new data suffers", "Slow convergence"]}', 'Fitting noise so new data suffers', 'Overfit models memorize training noise and generalize poorly.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444533');

-- AI-ML / Ensemble Learning (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444534', '22222222-2222-2222-2222-222222222321', 'Why do ensembles of diverse models help?', 'MCQ', 'MEDIUM', '{"options": ["They train faster in all cases", "They need less data in all cases", "Combining diverse models reduces error", "They remove feature engineering"]}', 'Combining diverse models reduces error', 'Averaging uncorrelated errors beats most single models.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444534');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444535', '22222222-2222-2222-2222-222222222321', 'What is voting in ensemble methods?', 'MCQ', 'MEDIUM', '{"options": ["Deleting weak models", "Splitting the dataset", "Aggregating member predictions", "Tuning the learning rate"]}', 'Aggregating member predictions', 'Voting or averaging fuses member outputs into one decision.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444535');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444536', '22222222-2222-2222-2222-222222222321', 'Bagging-style ensembles mainly reduce which error component?', 'MCQ', 'MEDIUM', '{"options": ["Bias in all cases", "Dataset size", "Feature count", "Variance"]}', 'Variance', 'Averaging independent-ish models damps variance while keeping bias.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444536');

-- AI-ML / Perceptron (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444537', '22222222-2222-2222-2222-222222222326', 'What is a perceptron?', 'MCQ', 'EASY', '{"options": ["A linear threshold unit combining weighted inputs", "A clustering method", "A sorting network", "A regular expression engine"]}', 'A linear threshold unit combining weighted inputs', 'The perceptron fires when the weighted sum crosses a threshold.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444537');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444538', '22222222-2222-2222-2222-222222222326', 'Which functions can a single perceptron learn?', 'MCQ', 'EASY', '{"options": ["Any function", "Only constant functions", "Linearly separable functions", "XOR of its inputs"]}', 'Linearly separable functions', 'One linear boundary cannot separate XOR-like patterns.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444538');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444539', '22222222-2222-2222-2222-222222222326', 'What does the perceptron learning rule adjust?', 'MCQ', 'EASY', '{"options": ["The dataset size", "The activation name", "Weights after misclassification", "The random seed"]}', 'Weights after misclassification', 'Weights move to correct mistakes and freeze once separated.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444539');

-- FDS / Data Science Fundamentals and Process (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444540', '22222222-2222-2222-2222-222222222330', 'What is CRISP-DM?', 'MCQ', 'EASY', '{"options": ["A data mining process methodology", "A chart type", "A Python library", "A file format"]}', 'A data mining process methodology', 'CRISP-DM structures projects from business understanding to deployment.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444540');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444541', '22222222-2222-2222-2222-222222222330', 'Which of these is a data science role?', 'MCQ', 'EASY', '{"options": ["Network router", "CSS designer", "Data analyst", "DNS administrator"]}', 'Data analyst', 'Analysts turn data into decisions; the rest are unrelated roles.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444541');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444542', '22222222-2222-2222-2222-222222222330', 'What comes first in a data science project?', 'MCQ', 'EASY', '{"options": ["Training models", "Deploying dashboards", "Understanding the business problem", "Tuning GPUs"]}', 'Understanding the business problem', 'Clear goals precede data collection and modelling.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444542');

-- FDS / Exploratory Data Analysis (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444543', '22222222-2222-2222-2222-222222222333', 'What is exploratory data analysis?', 'MCQ', 'MEDIUM', '{"options": ["Exploring data with summaries and plots before modelling", "Exporting data archives", "Encrypting datasets", "Erasing duplicates only"]}', 'Exploring data with summaries and plots before modelling', 'EDA builds intuition about distributions and quirks first.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444543');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444544', '22222222-2222-2222-2222-222222222333', 'Which plot best reveals a distribution shape?', 'MCQ', 'MEDIUM', '{"options": ["Pie chart of everything", "Histogram", "Scatter of row ids", "Bar of names only"]}', 'Histogram', 'Histograms bin values to expose shape, skew and modes.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444544');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444545', '22222222-2222-2222-2222-222222222333', 'What is an outlier?', 'MCQ', 'MEDIUM', '{"options": ["A missing value", "A column name", "A value far from the rest of the data", "A file header"]}', 'A value far from the rest of the data', 'Outliers may signal errors or genuinely rare events to handle.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444545');

-- FDS / NumPy (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444546', '22222222-2222-2222-2222-222222222340', 'What is a NumPy ndarray?', 'MCQ', 'EASY', '{"options": ["A fast N-dimensional array container", "A text file format", "A plot window", "A SQL table"]}', 'A fast N-dimensional array container', 'ndarrays store typed data contiguously for vectorized speed.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444546');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444547', '22222222-2222-2222-2222-222222222340', 'What is NumPy broadcasting?', 'MCQ', 'EASY', '{"options": ["Sending network packets", "Plotting bar charts", "Applying operations across compatible shapes", "Joining tables"]}', 'Applying operations across compatible shapes', 'Broadcasting stretches smaller shapes without copying data.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444547');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444548', '22222222-2222-2222-2222-222222222340', 'Which operation is vectorized?', 'MCQ', 'EASY', '{"options": ["A Python for loop appending items", "Manual per-index arithmetic", "arr * 2 on a NumPy array", "String concatenation in a loop"]}', 'arr * 2 on a NumPy array', 'Vectorized ops run in compiled code instead of Python loops.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444548');

-- FDS / Matplotlib (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444549', '22222222-2222-2222-2222-222222222346', 'What is the Figure in Matplotlib?', 'MCQ', 'MEDIUM', '{"options": ["The top-level container of a plot", "A legend entry", "A color map", "An axis tick"]}', 'The top-level container of a plot', 'Figures hold Axes, which hold the actual plotted artists.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444549');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444550', '22222222-2222-2222-2222-222222222346', 'Which call draws a line plot?', 'MCQ', 'MEDIUM', '{"options": ["plt.table", "plt.text", "plt.plot", "plt.savefig"]}', 'plt.plot', 'plt.plot renders line and marker series on the axes.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444550');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444551', '22222222-2222-2222-2222-222222222346', 'What does a plot legend communicate?', 'MCQ', 'MEDIUM', '{"options": ["The file size on disk", "Labels mapping plotted artists to meaning", "The axis limits", "The import list"]}', 'Labels mapping plotted artists to meaning', 'Legends decode which line or color stands for what.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444551');

-- DAA / Algorithm Fundamentals and Efficiency (EASY)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444552', '22222222-2222-2222-2222-222222222349', 'What does worst-case analysis measure?', 'MCQ', 'EASY', '{"options": ["The maximum cost over all inputs of a given size", "The average luck across runs", "The best possible hope", "The length of the source code"]}', 'The maximum cost over all inputs of a given size', 'Worst case bounds the cost no matter how adversarial the input.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444552');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444553', '22222222-2222-2222-2222-222222222349', 'Which dimensions measure algorithm efficiency?', 'MCQ', 'EASY', '{"options": ["Lines of comments", "Time and space growth", "Variable name length", "Number of source files"]}', 'Time and space growth', 'Efficiency is asymptotic time versus input size plus memory used.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444553');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444554', '22222222-2222-2222-2222-222222222349', 'What is an algorithm?', 'MCQ', 'EASY', '{"options": ["Any program bug", "A hardware chip", "A data file", "A finite step-by-step procedure solving a problem"]}', 'A finite step-by-step procedure solving a problem', 'Algorithms terminate with a correct output for valid inputs.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444554');

-- DAA / Pattern Matching and Naive Algorithm (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444555', '22222222-2222-2222-2222-222222222353', 'How does naive string matching work?', 'MCQ', 'MEDIUM', '{"options": ["Slides the pattern and checks each alignment", "Hashes the text once", "Sorts the text first", "Builds a suffix tree"]}', 'Slides the pattern and checks each alignment', 'Naive matching tries every position with direct comparison.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444555');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444556', '22222222-2222-2222-2222-222222222353', 'What is the worst-case time of naive matching on text length n and pattern length m?', 'MCQ', 'MEDIUM', '{"options": ["O(n)", "O(n*m)", "O(1)", "O(log n)"]}', 'O(n*m)', 'Up to n alignments each comparing up to m characters.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444556');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444557', '22222222-2222-2222-2222-222222222353', 'In that bound, what are n and m?', 'MCQ', 'MEDIUM', '{"options": ["Two prime numbers", "Node counts", "Text and pattern lengths", "Thread counts"]}', 'Text and pattern lengths', 'n counts text characters and m counts pattern characters.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444557');

-- DAA / Divide and Conquer Strategy (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444558', '22222222-2222-2222-2222-222222222358', 'What are the three divide-and-conquer phases?', 'MCQ', 'MEDIUM', '{"options": ["Divide, conquer, combine", "Guess, check, hope", "Sort, then ignore", "Loop until done"]}', 'Divide, conquer, combine', 'Split the instance, solve pieces, then merge the answers.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444558');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444559', '22222222-2222-2222-2222-222222222358', 'Which recurrence describes merge sort?', 'MCQ', 'MEDIUM', '{"options": ["T(n) = T(n-1) + 1", "T(n) = 2T(n/2) + O(n)", "T(n) = n factorial", "T(n) = O(1)"]}', 'T(n) = 2T(n/2) + O(n)', 'Two halves plus linear merge give Theta(n log n).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444559');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444560', '22222222-2222-2222-2222-222222222358', 'Which sorting algorithm is divide and conquer?', 'MCQ', 'MEDIUM', '{"options": ["Bubble sort", "Linear search", "Merge sort", "Insertion sort"]}', 'Merge sort', 'Merge sort halves the array and merges sorted halves.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444560');

-- DAA / Dynamic Programming Fundamentals (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444561', '22222222-2222-2222-2222-222222222362', 'When does dynamic programming apply?', 'MCQ', 'MEDIUM', '{"options": ["Overlapping subproblems with optimal substructure", "Sorted input only", "Tiny inputs only", "No repeated states"]}', 'Overlapping subproblems with optimal substructure', 'DP reuses solved subproblems that compose into optimal answers.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444561');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444562', '22222222-2222-2222-2222-222222222362', 'How do memoization and tabulation differ?', 'MCQ', 'MEDIUM', '{"options": ["Two sort orders", "Top-down caching versus bottom-up table filling", "RAM versus disk storage", "Compile time versus run time"]}', 'Top-down caching versus bottom-up table filling', 'Both avoid recomputation; direction and control flow differ.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444562');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444563', '22222222-2222-2222-2222-222222222362', 'Which is a classic dynamic programming example?', 'MCQ', 'MEDIUM', '{"options": ["Printing hello world", "Swapping two variables", "Fibonacci with repeated subcalls", "Drawing star patterns"]}', 'Fibonacci with repeated subcalls', 'Naive Fibonacci recomputes the same values DP would cache.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444563');

-- DAA / Greedy Techniques (MEDIUM)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444564', '22222222-2222-2222-2222-222222222366', 'What is the greedy choice property?', 'MCQ', 'MEDIUM', '{"options": ["A locally optimal choice leads to a global optimum", "Always pick at random", "Never look at the input", "Sort descending in all cases"]}', 'A locally optimal choice leads to a global optimum', 'With this property, committing locally never harms optimality.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444564');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444565', '22222222-2222-2222-2222-222222222366', 'Which algorithm is greedy?', 'MCQ', 'MEDIUM', '{"options": ["Merge sort", "Binary search", "Kruskal minimum spanning tree", "Depth-first search"]}', 'Kruskal minimum spanning tree', 'Kruskal repeatedly takes the cheapest safe edge.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444565');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444566', '22222222-2222-2222-2222-222222222366', 'When does a greedy strategy fail?', 'MCQ', 'MEDIUM', '{"options": ["The input is large", "The code is long", "Local optima mislead without the choice property", "Tests exist"]}', 'Local optima mislead without the choice property', 'Without the property, early commitments can block the optimum.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444566');

-- DAA / P NP NP Complete and NP Hard (HARD)
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444567', '22222222-2222-2222-2222-222222222372', 'What is complexity class P?', 'MCQ', 'HARD', '{"options": ["Problems with picture input", "Parallel programs", "Problems solvable in polynomial time", "Printer protocols"]}', 'Problems solvable in polynomial time', 'P captures tractable decision problems on deterministic machines.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444567');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444568', '22222222-2222-2222-2222-222222222372', 'What is complexity class NP?', 'MCQ', 'HARD', '{"options": ["Non-programmable tasks", "Network protocols", "Problems verifiable in polynomial time", "New programming paradigms"]}', 'Problems verifiable in polynomial time', 'NP solutions can be checked fast even when hard to find.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444568');
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at)
SELECT '44444444-4444-4444-4444-444444444569', '22222222-2222-2222-2222-222222222372', 'What is an NP-complete problem?', 'MCQ', 'HARD', '{"options": ["A completed project milestone", "A compiled program", "One of the hardest problems in NP, with all of NP reducing to it", "A finished correctness proof"]}', 'One of the hardest problems in NP, with all of NP reducing to it', 'NP-completeness ties the whole class together through reductions.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM questions WHERE id = '44444444-4444-4444-4444-444444444569');

-- ------------------------------------------------------------------
-- 2) Quizzes (29): 1 CURATED quiz per seeded topic, same topic order
-- ------------------------------------------------------------------
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555544', '22222222-2222-2222-2222-222222222244', 'Java Platform Challenge', 'Prove Java platform and program structure basics.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555544');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555545', '22222222-2222-2222-2222-222222222249', 'Classes and Objects Challenge', 'Demonstrate class and object fundamentals.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555545');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555546', '22222222-2222-2222-2222-222222222253', 'Inheritance Challenge', 'Apply inheritance mechanics and overriding rules.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555546');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555547', '22222222-2222-2222-2222-222222222258', 'Exception Handling Challenge', 'Handle exceptions with try, catch, finally and throws.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555547');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555548', '22222222-2222-2222-2222-222222222264', 'Process Models Challenge', 'Distinguish lifecycle models and agile practice.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555548');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555549', '22222222-2222-2222-2222-222222222267', 'OOAD Challenge', 'Model problem domains with objects and responsibilities.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555549');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555550', '22222222-2222-2222-2222-222222222270', 'Class Diagrams Challenge', 'Read classes, multiplicities and relationships.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555550');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555551', '22222222-2222-2222-2222-222222222274', 'Use Cases Challenge', 'Identify actors, use cases and system scope.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555551');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555552', '22222222-2222-2222-2222-222222222279', 'Domain Modelling Challenge', 'Extract conceptual classes from requirements.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555552');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555553', '22222222-2222-2222-2222-222222222287', 'HTML5 Challenge', 'Structure pages with elements and semantics.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555553');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555554', '22222222-2222-2222-2222-222222222291', 'JavaScript Challenge', 'Apply variables, types and strict equality.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555554');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555555', '22222222-2222-2222-2222-222222222296', 'Servlets Challenge', 'Handle requests through the servlet lifecycle.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555555');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555556', '22222222-2222-2222-2222-222222222299', 'PHP Challenge', 'Write server-side scripts with variables and forms.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555556');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555557', '22222222-2222-2222-2222-222222222303', 'React Challenge', 'Describe JSX, components and the virtual DOM.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555557');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555558', '22222222-2222-2222-2222-222222222306', 'Agents Challenge', 'Characterize intelligent agents and PEAS design.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555558');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555559', '22222222-2222-2222-2222-222222222312', 'Bayesian Inference Challenge', 'Update beliefs with priors and likelihood.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555559');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555560', '22222222-2222-2222-2222-222222222316', 'Linear Regression Challenge', 'Predict continuous values and spot overfitting.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555560');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555561', '22222222-2222-2222-2222-222222222321', 'Ensembles Challenge', 'Combine models to reduce error and variance.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555561');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555562', '22222222-2222-2222-2222-222222222326', 'Perceptron Challenge', 'Classify with linear threshold units.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555562');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555563', '22222222-2222-2222-2222-222222222330', 'Data Science Process Challenge', 'Frame projects with lifecycle thinking.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555563');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555564', '22222222-2222-2222-2222-222222222333', 'EDA Challenge', 'Explore distributions and spot outliers.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555564');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555565', '22222222-2222-2222-2222-222222222340', 'NumPy Challenge', 'Compute with arrays and broadcasting.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555565');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555566', '22222222-2222-2222-2222-222222222346', 'Matplotlib Challenge', 'Build figures, plots and legends.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555566');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555567', '22222222-2222-2222-2222-222222222349', 'Algorithm Analysis Challenge', 'Reason about cost and efficiency.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555567');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555568', '22222222-2222-2222-2222-222222222353', 'String Matching Challenge', 'Trace naive matching and its cost.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555568');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555569', '22222222-2222-2222-2222-222222222358', 'Divide and Conquer Challenge', 'Split, solve and combine with recurrences.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555569');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555570', '22222222-2222-2222-2222-222222222362', 'Dynamic Programming Challenge', 'Reuse overlapping subproblems bottom-up and top-down.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555570');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555571', '22222222-2222-2222-2222-222222222366', 'Greedy Challenge', 'Commit locally only when the choice property holds.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555571');
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at)
SELECT '55555555-5555-5555-5555-555555555572', '22222222-2222-2222-2222-222222222372', 'Complexity Classes Challenge', 'Separate P, NP and NP-completeness.', 'HARD', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quizzes WHERE id = '55555555-5555-5555-5555-555555555572');

-- ------------------------------------------------------------------
-- 3) QuizQuestions (87): 3 same-topic links per quiz, ordered 1..3
-- ------------------------------------------------------------------
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666661', '55555555-5555-5555-5555-555555555544', '44444444-4444-4444-4444-444444444483', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666661');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666662', '55555555-5555-5555-5555-555555555544', '44444444-4444-4444-4444-444444444484', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666662');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666663', '55555555-5555-5555-5555-555555555544', '44444444-4444-4444-4444-444444444485', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666663');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666664', '55555555-5555-5555-5555-555555555545', '44444444-4444-4444-4444-444444444486', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666664');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666665', '55555555-5555-5555-5555-555555555545', '44444444-4444-4444-4444-444444444487', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666665');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666666', '55555555-5555-5555-5555-555555555545', '44444444-4444-4444-4444-444444444488', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666666');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666667', '55555555-5555-5555-5555-555555555546', '44444444-4444-4444-4444-444444444489', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666667');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666668', '55555555-5555-5555-5555-555555555546', '44444444-4444-4444-4444-444444444490', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666668');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666669', '55555555-5555-5555-5555-555555555546', '44444444-4444-4444-4444-444444444491', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666669');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666670', '55555555-5555-5555-5555-555555555547', '44444444-4444-4444-4444-444444444492', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666670');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666671', '55555555-5555-5555-5555-555555555547', '44444444-4444-4444-4444-444444444493', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666671');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666672', '55555555-5555-5555-5555-555555555547', '44444444-4444-4444-4444-444444444494', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666672');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666673', '55555555-5555-5555-5555-555555555548', '44444444-4444-4444-4444-444444444495', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666673');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666674', '55555555-5555-5555-5555-555555555548', '44444444-4444-4444-4444-444444444496', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666674');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666675', '55555555-5555-5555-5555-555555555548', '44444444-4444-4444-4444-444444444497', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666675');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666676', '55555555-5555-5555-5555-555555555549', '44444444-4444-4444-4444-444444444498', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666676');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666677', '55555555-5555-5555-5555-555555555549', '44444444-4444-4444-4444-444444444499', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666677');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666678', '55555555-5555-5555-5555-555555555549', '44444444-4444-4444-4444-444444444500', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666678');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666679', '55555555-5555-5555-5555-555555555550', '44444444-4444-4444-4444-444444444501', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666679');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666680', '55555555-5555-5555-5555-555555555550', '44444444-4444-4444-4444-444444444502', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666680');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666681', '55555555-5555-5555-5555-555555555550', '44444444-4444-4444-4444-444444444503', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666681');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666682', '55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444504', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666682');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666683', '55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444505', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666683');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666684', '55555555-5555-5555-5555-555555555551', '44444444-4444-4444-4444-444444444506', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666684');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666685', '55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444507', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666685');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666686', '55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444508', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666686');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666687', '55555555-5555-5555-5555-555555555552', '44444444-4444-4444-4444-444444444509', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666687');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666688', '55555555-5555-5555-5555-555555555553', '44444444-4444-4444-4444-444444444510', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666688');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666689', '55555555-5555-5555-5555-555555555553', '44444444-4444-4444-4444-444444444511', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666689');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666690', '55555555-5555-5555-5555-555555555553', '44444444-4444-4444-4444-444444444512', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666690');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666691', '55555555-5555-5555-5555-555555555554', '44444444-4444-4444-4444-444444444513', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666691');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666692', '55555555-5555-5555-5555-555555555554', '44444444-4444-4444-4444-444444444514', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666692');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666693', '55555555-5555-5555-5555-555555555554', '44444444-4444-4444-4444-444444444515', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666693');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666694', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444516', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666694');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666695', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444517', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666695');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666696', '55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444518', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666696');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666697', '55555555-5555-5555-5555-555555555556', '44444444-4444-4444-4444-444444444519', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666697');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666698', '55555555-5555-5555-5555-555555555556', '44444444-4444-4444-4444-444444444520', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666698');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666699', '55555555-5555-5555-5555-555555555556', '44444444-4444-4444-4444-444444444521', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666699');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666700', '55555555-5555-5555-5555-555555555557', '44444444-4444-4444-4444-444444444522', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666700');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666701', '55555555-5555-5555-5555-555555555557', '44444444-4444-4444-4444-444444444523', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666701');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666702', '55555555-5555-5555-5555-555555555557', '44444444-4444-4444-4444-444444444524', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666702');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666703', '55555555-5555-5555-5555-555555555558', '44444444-4444-4444-4444-444444444525', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666703');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666704', '55555555-5555-5555-5555-555555555558', '44444444-4444-4444-4444-444444444526', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666704');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666705', '55555555-5555-5555-5555-555555555558', '44444444-4444-4444-4444-444444444527', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666705');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666706', '55555555-5555-5555-5555-555555555559', '44444444-4444-4444-4444-444444444528', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666706');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666707', '55555555-5555-5555-5555-555555555559', '44444444-4444-4444-4444-444444444529', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666707');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666708', '55555555-5555-5555-5555-555555555559', '44444444-4444-4444-4444-444444444530', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666708');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666709', '55555555-5555-5555-5555-555555555560', '44444444-4444-4444-4444-444444444531', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666709');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666710', '55555555-5555-5555-5555-555555555560', '44444444-4444-4444-4444-444444444532', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666710');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666711', '55555555-5555-5555-5555-555555555560', '44444444-4444-4444-4444-444444444533', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666711');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666712', '55555555-5555-5555-5555-555555555561', '44444444-4444-4444-4444-444444444534', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666712');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666713', '55555555-5555-5555-5555-555555555561', '44444444-4444-4444-4444-444444444535', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666713');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666714', '55555555-5555-5555-5555-555555555561', '44444444-4444-4444-4444-444444444536', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666714');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666715', '55555555-5555-5555-5555-555555555562', '44444444-4444-4444-4444-444444444537', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666715');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666716', '55555555-5555-5555-5555-555555555562', '44444444-4444-4444-4444-444444444538', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666716');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666717', '55555555-5555-5555-5555-555555555562', '44444444-4444-4444-4444-444444444539', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666717');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666718', '55555555-5555-5555-5555-555555555563', '44444444-4444-4444-4444-444444444540', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666718');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666719', '55555555-5555-5555-5555-555555555563', '44444444-4444-4444-4444-444444444541', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666719');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666720', '55555555-5555-5555-5555-555555555563', '44444444-4444-4444-4444-444444444542', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666720');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666721', '55555555-5555-5555-5555-555555555564', '44444444-4444-4444-4444-444444444543', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666721');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666722', '55555555-5555-5555-5555-555555555564', '44444444-4444-4444-4444-444444444544', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666722');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666723', '55555555-5555-5555-5555-555555555564', '44444444-4444-4444-4444-444444444545', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666723');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666724', '55555555-5555-5555-5555-555555555565', '44444444-4444-4444-4444-444444444546', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666724');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666725', '55555555-5555-5555-5555-555555555565', '44444444-4444-4444-4444-444444444547', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666725');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666726', '55555555-5555-5555-5555-555555555565', '44444444-4444-4444-4444-444444444548', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666726');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666727', '55555555-5555-5555-5555-555555555566', '44444444-4444-4444-4444-444444444549', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666727');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666728', '55555555-5555-5555-5555-555555555566', '44444444-4444-4444-4444-444444444550', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666728');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666729', '55555555-5555-5555-5555-555555555566', '44444444-4444-4444-4444-444444444551', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666729');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666730', '55555555-5555-5555-5555-555555555567', '44444444-4444-4444-4444-444444444552', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666730');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666731', '55555555-5555-5555-5555-555555555567', '44444444-4444-4444-4444-444444444553', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666731');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666732', '55555555-5555-5555-5555-555555555567', '44444444-4444-4444-4444-444444444554', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666732');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666733', '55555555-5555-5555-5555-555555555568', '44444444-4444-4444-4444-444444444555', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666733');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666734', '55555555-5555-5555-5555-555555555568', '44444444-4444-4444-4444-444444444556', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666734');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666735', '55555555-5555-5555-5555-555555555568', '44444444-4444-4444-4444-444444444557', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666735');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666736', '55555555-5555-5555-5555-555555555569', '44444444-4444-4444-4444-444444444558', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666736');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666737', '55555555-5555-5555-5555-555555555569', '44444444-4444-4444-4444-444444444559', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666737');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666738', '55555555-5555-5555-5555-555555555569', '44444444-4444-4444-4444-444444444560', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666738');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666739', '55555555-5555-5555-5555-555555555570', '44444444-4444-4444-4444-444444444561', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666739');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666740', '55555555-5555-5555-5555-555555555570', '44444444-4444-4444-4444-444444444562', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666740');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666741', '55555555-5555-5555-5555-555555555570', '44444444-4444-4444-4444-444444444563', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666741');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666742', '55555555-5555-5555-5555-555555555571', '44444444-4444-4444-4444-444444444564', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666742');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666743', '55555555-5555-5555-5555-555555555571', '44444444-4444-4444-4444-444444444565', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666743');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666744', '55555555-5555-5555-5555-555555555571', '44444444-4444-4444-4444-444444444566', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666744');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666745', '55555555-5555-5555-5555-555555555572', '44444444-4444-4444-4444-444444444567', 1, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666745');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666746', '55555555-5555-5555-5555-555555555572', '44444444-4444-4444-4444-444444444568', 2, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666746');
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at)
SELECT '66666666-6666-6666-6666-666666666747', '55555555-5555-5555-5555-555555555572', '44444444-4444-4444-4444-444444444569', 3, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM quiz_questions WHERE id = '66666666-6666-6666-6666-666666666747');
