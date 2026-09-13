-- GameLearn AI - Batch 1 / Phase 2: syllabus expansion for the 6 new subjects.
-- Adds 29 units and 134 topics covering the supplied syllabus scope.
-- Deterministic reserved namespaces continuing the existing blocks:
--   units  : 77777777-7777-7777-7777-777777777701..729
--   topics : 22222222-2222-2222-2222-222222222244..377
--     OOP  (111...106): topics 244-263 (20), units 701-704
--     OOSE (111...107): topics 264-286 (23), units 705-709
--     Web  (111...108): topics 287-305 (19), units 710-714
--     AIML (111...109): topics 306-329 (24), units 715-719
--     FDS  (111...110): topics 330-348 (19), units 720-723
--     DAA  (111...111): topics 349-377 (29), units 724-729
-- Every statement is INSERT...SELECT...WHERE NOT EXISTS (H2 + MySQL
-- portable): re-running never duplicates. Additive only: existing subjects,
-- units and topics are untouched (pre-Batch-1 topics keep unit_id NULL).

-- ------------------------------------------------------------------
-- 1) Units (29)
-- ------------------------------------------------------------------

-- Object Oriented Programming (units 701-704)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777701', '11111111-1111-1111-1111-111111111106', 'Java Fundamentals and Data Types', 'Java platform, data types, variables, operators and control flow.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777701');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777702', '11111111-1111-1111-1111-111111111106', 'Classes Objects and Constructors', 'Classes, objects, constructors, static and final members, strings.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777702');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777703', '11111111-1111-1111-1111-111111111106', 'Inheritance and Polymorphism', 'Inheritance, polymorphism, abstract classes and interfaces.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777703');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777704', '11111111-1111-1111-1111-111111111106', 'Packages Exceptions and Advanced Java', 'Packages, exception handling, multithreading, collections, I-O streams, JavaFX and JDBC.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777704');

-- Object Oriented Software Engineering (units 705-709)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777705', '11111111-1111-1111-1111-111111111107', 'Software Process and Requirements', 'Software engineering, process models, requirements analysis and SRS.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777705');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777706', '11111111-1111-1111-1111-111111111107', 'OOAD and UML Architecture', 'Object oriented analysis and design, UML architecture and relationships.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777706');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777707', '11111111-1111-1111-1111-111111111107', 'Structural UML Diagrams', 'Class, object, package and component diagrams.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777707');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777708', '11111111-1111-1111-1111-111111111107', 'Behavioral UML Diagrams', 'Use case, sequence, communication, activity and state machine diagrams.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777708');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777709', '11111111-1111-1111-1111-111111111107', 'Design Principles and Implementation', 'Domain modelling, SOLID, design patterns, UML to code mapping, testing, refactoring and case studies.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777709');

-- Web Technologies (units 710-714)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777710', '11111111-1111-1111-1111-111111111108', 'HTML5 and CSS3', 'HTML5 structure, forms, media, CSS3 styling, layouts and responsive design.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777710');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777711', '11111111-1111-1111-1111-111111111108', 'JavaScript and DOM', 'JavaScript language, DOM manipulation, events and exception handling.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777711');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777712', '11111111-1111-1111-1111-111111111108', 'Server Side Java', 'Servlets, sessions, cookies and JDBC in web applications.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777712');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777713', '11111111-1111-1111-1111-111111111108', 'PHP and XML Technologies', 'PHP scripting, XML with DTD and Schema, XSL transforms and AJAX.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777713');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777714', '11111111-1111-1111-1111-111111111108', 'React', 'React with JSX, components, props and styling.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777714');

-- Artificial Intelligence and Machine Learning (units 715-719)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777715', '11111111-1111-1111-1111-111111111109', 'AI Foundations and Search', 'Agents, uninformed and heuristic search, local and adversarial search, constraint satisfaction.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777715');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777716', '11111111-1111-1111-1111-111111111109', 'Probabilistic Reasoning', 'Bayesian inference, Naive Bayes, Bayesian and causal networks.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777716');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777717', '11111111-1111-1111-1111-111111111109', 'Supervised Learning', 'Linear and logistic regression, SVM, decision trees and KNN.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777717');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777718', '11111111-1111-1111-1111-111111111109', 'Ensembles and Unsupervised Learning', 'Ensembles, bagging, boosting, stacking, K-means, mixtures and EM.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777718');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777719', '11111111-1111-1111-1111-111111111109', 'Neural Networks', 'Perceptron, gradient descent, backpropagation, normalization and regularization.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777719');

-- Foundations of Data Science (units 720-723)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777720', '11111111-1111-1111-1111-111111111110', 'Data Science Process', 'Data science fundamentals, research goals, retrieval and preparation.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777720');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777721', '11111111-1111-1111-1111-111111111110', 'Exploratory Analysis and Statistics', 'EDA, statistical descriptions, distributions, correlation and regression.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777721');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777722', '11111111-1111-1111-1111-111111111110', 'NumPy and Pandas', 'Array computing, dataframes, selection, missing data, combining and aggregation.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777722');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777723', '11111111-1111-1111-1111-111111111110', 'Data Visualization', 'Matplotlib, Seaborn, 3D and geographic visualization.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777723');

-- Design and Analysis of Algorithms (units 724-729)
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777724', '11111111-1111-1111-1111-111111111111', 'Algorithm Foundations', 'Fundamentals, efficiency, asymptotic analysis, brute force and basic search.', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777724');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777725', '11111111-1111-1111-1111-111111111111', 'String Matching and Exhaustive Search', 'Pattern matching algorithms and exhaustive search exemplars.', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777725');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777726', '11111111-1111-1111-1111-111111111111', 'Divide and Conquer', 'Divide and conquer strategy, sorting, searching and Strassen multiplication.', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777726');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777727', '11111111-1111-1111-1111-111111111111', 'Dynamic Programming', 'DP fundamentals, Warshall, Floyd, optimal BST and matrix chain multiplication.', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777727');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777728', '11111111-1111-1111-1111-111111111111', 'Greedy Techniques and Flow', 'Greedy methods, MST, shortest paths, Huffman coding, flow and matching.', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777728');
INSERT INTO units (id, subject_id, name, description, display_order, is_active, created_at, updated_at)
SELECT '77777777-7777-7777-7777-777777777729', '11111111-1111-1111-1111-111111111111', 'Complexity Backtracking and Approximation', 'Lower bounds, P and NP, reductions, backtracking, branch and bound, approximation.', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM units WHERE id = '77777777-7777-7777-7777-777777777729');

-- ------------------------------------------------------------------
-- 2) Topics (134)
-- Columns: id, subject_id, unit_id, name, description, difficulty,
-- display_order (1..N per subject), is_active.
-- ------------------------------------------------------------------

-- Object Oriented Programming: topics 244-263 (20)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222244', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777701', 'Java Platform and Program Structure', 'JVM, JRE and JDK roles, anatomy of a Java program, the main method, compilation and execution.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222244');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222245', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777701', 'Data Types', 'Primitive types with ranges and defaults, reference types, type conversion and casting.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222245');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222246', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777701', 'Variables and Literals', 'Declaration and initialization, scope basics, constants and naming conventions.', 'EASY', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222246');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222247', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777701', 'Operators', 'Arithmetic, relational, logical, bitwise and assignment operators, precedence and associativity.', 'EASY', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222247');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222248', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777701', 'Control Flow in Java', 'If else and switch selection, while, do while and for loops, break and continue.', 'EASY', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222248');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222249', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777702', 'Classes and Objects', 'Class anatomy, fields and methods, object creation, references and garbage collection basics.', 'MEDIUM', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222249');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222250', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777702', 'Constructors', 'Default and parameterized constructors, overloading, constructor chaining with this.', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222250');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222251', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777702', 'Static and Final Members', 'Static fields, methods and blocks, final variables, methods and classes, constants.', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222251');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222252', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777702', 'Strings', 'String immutability, StringBuilder and StringBuffer, common operations and comparisons.', 'MEDIUM', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222252');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222253', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777703', 'Inheritance', 'Extends and super, method overriding, hierarchical design and protected access.', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222253');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222254', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777703', 'Polymorphism', 'Upcasting, dynamic dispatch, overloading versus overriding, instanceof checks.', 'MEDIUM', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222254');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222255', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777703', 'Abstract Classes', 'Abstract methods, the template method shape, abstract versus concrete design.', 'MEDIUM', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222255');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222256', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777703', 'Interfaces', 'Interface contracts, multiple inheritance of type, default and static methods, functional interfaces.', 'MEDIUM', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222256');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222257', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'Packages and Access Control', 'Package layout, imports, access modifiers and encapsulation boundaries.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222257');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222258', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'Exception Handling', 'Exception hierarchy, try catch finally, throw and throws, custom exceptions.', 'MEDIUM', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222258');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222259', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'Multithreading', 'Thread lifecycle, Runnable, synchronization and basic concurrency hazards.', 'HARD', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222259');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222260', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'Collections Framework', 'List, Set and Map, ArrayList, HashMap and HashSet, iteration and generics basics.', 'HARD', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222260');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222261', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'I-O Streams', 'Byte versus character streams, file I-O, buffering and try with resources.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222261');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222262', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'JavaFX Basics', 'Stage, scene and graph structure, controls, layouts and event driven UI shape.', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222262');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222263', '11111111-1111-1111-1111-111111111106', '77777777-7777-7777-7777-777777777704', 'JDBC', 'Drivers, connections, statements, result sets and prepared statements.', 'HARD', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222263');

-- Object Oriented Software Engineering: topics 264-286 (23)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222264', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777705', 'Software Engineering and Process Models', 'Software development lifecycle, waterfall, iterative and agile Scrum essentials.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222264');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222265', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777705', 'Requirements Analysis', 'Elicitation, functional versus non-functional requirements and analysis techniques.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222265');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222266', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777705', 'Software Requirements Specification', 'SRS structure, characteristics of good requirements and traceability.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222266');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222267', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777706', 'Object Oriented Analysis and Design', 'Objects and responsibilities, moving from requirements to object models.', 'MEDIUM', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222267');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222268', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777706', 'UML Architecture and Views', 'UML building blocks, the 4 plus 1 views and the diagram taxonomy.', 'MEDIUM', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222268');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222269', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777706', 'UML Relationships', 'Association, aggregation, composition, generalization, dependency and realization.', 'MEDIUM', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222269');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222270', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777707', 'Class Diagrams', 'Classes, attributes, operations, multiplicities and associations in structural modelling.', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222270');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222271', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777707', 'Object Diagrams', 'Instances and links, snapshots of structure at runtime.', 'EASY', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222271');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222272', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777707', 'Package Diagrams', 'Namespaces, layering and package dependencies.', 'MEDIUM', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222272');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222273', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777707', 'Component Diagrams', 'Components, provided and required interfaces and deployment level structure.', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222273');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222274', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777708', 'Use Case Diagrams', 'Actors, use cases, include and extend, the system boundary.', 'EASY', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222274');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222275', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777708', 'Sequence Diagrams', 'Lifelines, messages, activation bars and alt opt fragments.', 'MEDIUM', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222275');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222276', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777708', 'Communication Diagrams', 'Links and numbering with a collaboration focus on the same interactions as sequences.', 'MEDIUM', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222276');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222277', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777708', 'Activity Diagrams', 'Actions, forks and joins, swimlanes and workflow modelling.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222277');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222278', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777708', 'State Machine Diagrams', 'States, transitions, guards and nested states for lifecycle modelling.', 'HARD', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222278');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222279', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'Domain Modelling', 'Conceptual classes and associations, deriving the domain model from use cases.', 'MEDIUM', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222279');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222280', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'SOLID Principles', 'Single responsibility through dependency inversion, with object oriented examples.', 'MEDIUM', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222280');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222281', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'Design Patterns', 'Creational, structural and behavioral essentials: Singleton, Factory, Observer and Strategy.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222281');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222282', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'UML to Code Mapping', 'Forward engineering classes, associations and messages into code skeletons.', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222282');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222283', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'Testing Object Oriented Software', 'Unit, integration and system testing, test design for object oriented code.', 'HARD', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222283');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222284', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'Refactoring', 'Code smells, safe behavior preserving transformations and refactoring rhythm.', 'MEDIUM', 21, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222284');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222285', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'Forward and Reverse Engineering', 'Round trip engineering and recovering models from existing code.', 'MEDIUM', 22, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222285');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222286', '11111111-1111-1111-1111-111111111107', '77777777-7777-7777-7777-777777777709', 'OOSE Case Studies', 'End to end worked studies tying process, UML modelling and code together.', 'MEDIUM', 23, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222286');

-- Web Technologies: topics 287-305 (19)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222287', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777710', 'HTML5 Fundamentals', 'Document structure, elements, attributes and semantic tags.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222287');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222288', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777710', 'HTML5 Forms and Media', 'Forms, inputs and validation, audio, video and canvas overview.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222288');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222289', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777710', 'CSS3 Styling and Box Model', 'Selectors, the cascade, box model, colors and typography.', 'EASY', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222289');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222290', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777710', 'CSS3 Layouts and Responsive Design', 'Flexbox, grid, media queries and mobile first design.', 'MEDIUM', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222290');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222291', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777711', 'JavaScript Fundamentals', 'Syntax, types, functions, arrays, objects and ES6 essentials.', 'EASY', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222291');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222292', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777711', 'Functions Scope and Objects', 'Closures, the this keyword, prototypes and classes.', 'MEDIUM', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222292');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222293', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777711', 'DOM Manipulation', 'Selecting, traversing, creating and updating document nodes.', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222293');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222294', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777711', 'Event Handling', 'Listeners, propagation, delegation and common UI events.', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222294');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222295', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777711', 'Exception Handling in JavaScript', 'Try catch finally, error objects and async error basics.', 'MEDIUM', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222295');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222296', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777712', 'Servlets', 'Servlet lifecycle, requests and responses, annotations and deployment shape.', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222296');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222297', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777712', 'Sessions and Cookies', 'State management, session tracking and cookie handling.', 'MEDIUM', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222297');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222298', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777712', 'JDBC in Web Applications', 'Connection handling, DAO shape and transaction basics inside servlets.', 'HARD', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222298');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222299', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777713', 'PHP Fundamentals', 'PHP syntax, form handling, sessions and server side scripting flow.', 'EASY', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222299');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222300', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777713', 'XML DTD and XML Schema', 'Well formed XML, DTD validation and XSD types.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222300');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222301', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777713', 'XSL and XSLT', 'Stylesheets, templates and transforming XML into HTML.', 'MEDIUM', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222301');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222302', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777713', 'AJAX', 'Partial page updates with XMLHttpRequest and fetch, JSON exchange.', 'MEDIUM', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222302');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222303', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777714', 'React and JSX', 'Component thinking, JSX syntax, rendering and the virtual DOM idea.', 'MEDIUM', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222303');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222304', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777714', 'Components and Props', 'Function components, props flow, composition and lists with keys.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222304');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222305', '11111111-1111-1111-1111-111111111108', '77777777-7777-7777-7777-777777777714', 'React Styling', 'Inline styles, CSS modules, conditional classes and styling approaches.', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222305');

-- Artificial Intelligence and Machine Learning: topics 306-329 (24)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222306', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'AI and Problem Solving Agents', 'Agents, environments, PEAS descriptions and agent types.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222306');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222307', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'Uninformed Search', 'Breadth first, depth first, uniform cost, depth limited and iterative deepening search.', 'MEDIUM', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222307');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222308', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'Heuristic Search', 'Greedy best first and A star search, admissibility and consistency.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222308');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222309', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'Local Search and Optimization', 'Hill climbing, simulated annealing, local beam search and genetic algorithms.', 'MEDIUM', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222309');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222310', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'Adversarial Search', 'Minimax, alpha beta pruning and expectimax basics.', 'HARD', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222310');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222311', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777715', 'Constraint Satisfaction Problems', 'Backtracking search, forward checking and arc consistency.', 'HARD', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222311');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222312', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777716', 'Bayesian Inference', 'Bayes rule, priors and posteriors and common inference patterns.', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222312');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222313', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777716', 'Naive Bayes', 'The independence assumption and the text classification shape.', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222313');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222314', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777716', 'Bayesian Networks', 'Network structure, conditional independence and inference.', 'HARD', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222314');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222315', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777716', 'Causal Networks', 'Interventions, causal direction and confounding basics.', 'HARD', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222315');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222316', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777717', 'Linear Regression', 'Hypothesis and cost, closed form versus iterative fitting.', 'EASY', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222316');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222317', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777717', 'Logistic Regression', 'Sigmoid function, decision boundary and binary classification.', 'MEDIUM', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222317');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222318', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777717', 'Support Vector Machines', 'Margins, kernels and the regularization parameter.', 'HARD', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222318');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222319', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777717', 'Decision Trees', 'Splits, impurity measures, pruning and overfitting control.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222319');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222320', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777717', 'K Nearest Neighbours', 'Distance measures, choosing k and lazy learning trade offs.', 'EASY', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222320');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222321', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777718', 'Ensemble Learning', 'Bias and variance, why ensembles help, voting strategies.', 'MEDIUM', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222321');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222322', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777718', 'Bagging and Boosting', 'Random forests idea, AdaBoost and gradient boosting shape.', 'MEDIUM', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222322');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222323', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777718', 'Stacking', 'Meta learners and blending predictions.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222323');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222324', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777718', 'K Means Clustering', 'Assignment and update steps, choosing k and limitations.', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222324');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222325', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777718', 'Gaussian Mixtures and Expectation Maximization', 'Soft assignment and the EM steps for mixture models.', 'HARD', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222325');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222326', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777719', 'Perceptron', 'The linear threshold unit and the perceptron learning rule.', 'EASY', 21, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222326');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222327', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777719', 'Neural Networks and Gradient Descent', 'Layers, activations, loss functions and gradient descent.', 'MEDIUM', 22, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222327');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222328', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777719', 'Backpropagation', 'Chain rule flow, weight updates and the training loop.', 'HARD', 23, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222328');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222329', '11111111-1111-1111-1111-111111111109', '77777777-7777-7777-7777-777777777719', 'Batch Normalization Regularization and Dropout', 'Stabilizing and generalizing deep network training.', 'HARD', 24, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222329');

-- Foundations of Data Science: topics 330-348 (19)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222330', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777720', 'Data Science Fundamentals and Process', 'Data science lifecycle, team roles and the CRISP DM shape.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222330');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222331', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777720', 'Research Goals', 'Framing questions, hypotheses and success criteria.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222331');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222332', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777720', 'Data Retrieval and Preparation', 'Data sources, cleaning and feature typing before analysis.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222332');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222333', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Exploratory Data Analysis', 'Summaries, distributions and outlier spotting to understand data.', 'MEDIUM', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222333');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222334', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Statistical Descriptions', 'Population versus sample and the core descriptive measures.', 'EASY', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222334');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222335', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Data Types and Variables', 'Categorical and numerical data, scales of measurement.', 'EASY', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222335');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222336', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Tables and Graphs', 'Frequency tables and reading bar, histogram and box plots.', 'EASY', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222336');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222337', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Averages and Variability', 'Mean, median and mode, range, variance and standard deviation.', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222337');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222338', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Normal Distributions', 'The empirical rule, z scores and normality checks.', 'MEDIUM', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222338');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222339', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777721', 'Correlation Scatter Plots and Regression', 'Covariance, Pearson r, scatter reading and the regression line.', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222339');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222340', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'NumPy', 'Arrays, shapes, broadcasting and vectorized operations.', 'EASY', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222340');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222341', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'Pandas and Data Manipulation', 'Series and DataFrame, data I-O and inspection workflows.', 'MEDIUM', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222341');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222342', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'Data Selection and Indexing', 'Label and positional indexing, boolean masks and filtering.', 'MEDIUM', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222342');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222343', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'Missing Data', 'Detection, imputation versus deletion trade offs.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222343');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222344', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'Combining Datasets', 'Concatenation and merge join types across datasets.', 'MEDIUM', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222344');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222345', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777722', 'Aggregation Grouping and Pivot Tables', 'Group by splits, aggregations and pivot tables.', 'MEDIUM', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222345');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222346', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777723', 'Matplotlib', 'Figure and axes, line, bar, histogram and scatter plots, labels and legends.', 'MEDIUM', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222346');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222347', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777723', 'Seaborn', 'Statistical plots, hues, themes and regression plots.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222347');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222348', '11111111-1111-1111-1111-111111111110', '77777777-7777-7777-7777-777777777723', '3D and Geographic Visualization', 'Three dimensional axes, choropleth and point map concepts.', 'HARD', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222348');

-- Design and Analysis of Algorithms: topics 349-377 (29)
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222349', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777724', 'Algorithm Fundamentals and Efficiency', 'Correctness, efficiency dimensions and best, worst and average case thinking.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222349');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222350', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777724', 'Asymptotic Analysis', 'Big O, Omega and Theta notation, growth rates and analysis rules.', 'MEDIUM', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222350');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222351', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777724', 'Brute Force', 'Exhaustive enumeration strategy and when it fits.', 'EASY', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222351');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222352', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777724', 'Sequential and Interpolation Search', 'Linear scan and sorted array interpolation search.', 'EASY', 4, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222352');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222353', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777725', 'Pattern Matching and Naive Algorithm', 'Naive string matching mechanics and complexity.', 'MEDIUM', 5, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222353');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222354', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777725', 'Rabin Karp Algorithm', 'Rolling hash, average case speed and collision handling.', 'MEDIUM', 6, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222354');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222355', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777725', 'Knuth Morris Pratt Algorithm', 'Prefix function and linear time string matching.', 'MEDIUM', 7, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222355');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222356', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777725', 'Exhaustive Search', 'State spaces and combinatorial explosion in exhaustive strategies.', 'MEDIUM', 8, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222356');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222357', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777725', 'TSP Knapsack and Assignment', 'Classic hard exemplars: travelling salesman, knapsack and assignment problem statements.', 'HARD', 9, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222357');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222358', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777726', 'Divide and Conquer Strategy', 'The divide and combine pattern and recurrence thinking.', 'MEDIUM', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222358');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222359', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777726', 'Merge Sort and Quick Sort', 'Partition and merge mechanics, average versus worst case behavior.', 'MEDIUM', 11, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222359');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222360', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777726', 'Binary Search and Min Max', 'Halving search and simultaneous minimum maximum finding.', 'EASY', 12, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222360');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222361', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777726', 'Strassen Matrix Multiplication', 'The subcubic divide and conquer idea and its recurrence payoff.', 'HARD', 13, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222361');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222362', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777727', 'Dynamic Programming Fundamentals', 'Overlapping subproblems, memoization versus tabulation.', 'MEDIUM', 14, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222362');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222363', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777727', 'Warshall and Floyd Algorithms', 'Transitive closure and all pairs shortest paths.', 'MEDIUM', 15, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222363');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222364', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777727', 'Optimal BST and Multistage Graphs', 'Optimal substructure in trees and staged decisions.', 'HARD', 16, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222364');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222365', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777727', 'Matrix Chain Multiplication', 'Parenthesization dynamic programming and the cost recurrence.', 'HARD', 17, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222365');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222366', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777728', 'Greedy Techniques', 'The greedy choice property and correctness arguments.', 'MEDIUM', 18, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222366');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222367', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777728', 'Prim and Kruskal Algorithms', 'Minimum spanning tree cuts and the union find shape.', 'MEDIUM', 19, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222367');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222368', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777728', 'Dijkstra and Huffman Coding', 'Shortest paths with non negative weights and optimal prefix codes.', 'MEDIUM', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222368');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222369', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777728', 'Iterative Improvement and Maximum Flow', 'Residual graphs, augmenting paths and the max flow min cut idea.', 'HARD', 21, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222369');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222370', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777728', 'Maximum Matching and Stable Marriage', 'Bipartite matching and the Gale Shapley proposal algorithm.', 'HARD', 22, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222370');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222371', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Lower Bounds', 'Decision tree and adversary arguments for optimality.', 'MEDIUM', 23, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222371');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222372', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'P NP NP Complete and NP Hard', 'Complexity classes, verifiers and the completeness idea.', 'HARD', 24, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222372');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222373', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Reductions', 'Polynomial reductions and the shape of hardness proofs.', 'HARD', 25, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222373');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222374', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Backtracking and N Queens', 'Constraint propagation in search, worked through N Queens.', 'MEDIUM', 26, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222374');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222375', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Hamiltonian Circuit and Subset Sum', 'Classic hard problems and their backtracking attempts.', 'HARD', 27, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222375');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222376', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Branch and Bound', 'Bounding, pruning and search order in combinatorial optimization.', 'HARD', 28, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222376');
INSERT INTO topics (id, subject_id, unit_id, name, description, difficulty, display_order, is_active, created_at, updated_at)
SELECT '22222222-2222-2222-2222-222222222377', '11111111-1111-1111-1111-111111111111', '77777777-7777-7777-7777-777777777729', 'Approximation Algorithms', 'Approximation ratios and greedy metric approximations.', 'HARD', 29, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM topics WHERE id = '22222222-2222-2222-2222-222222222377');
