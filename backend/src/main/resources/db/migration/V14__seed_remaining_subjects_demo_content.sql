-- GameLearn AI - Remaining subjects demo content (Phase 3B)
-- Makes the 5 current worlds genuinely playable end-to-end.
-- Programming already has V12 (3 topics, 12Q, 3 quizzes).
-- This migration adds 3 topics + 1 lesson per topic + 4 MCQ per topic + 1 quiz per topic
-- for the other 4 seeded subjects, using the same CURATED, is_active=true,
-- deterministic UUID pattern as V12. No user data, no DELETE, additive only.
--
-- Subjects (V11):
--   111...1102 Computer Networks
--   111...1103 DBMS
--   111...1104 Operating Systems
--   111...1105 Data Structures
--
-- New namespaces (all deterministic):
--   topics  : 222...214-216 (Networks), 221-223 (DBMS), 231-233 (OS), 241-243 (DS)
--   lessons : 333...314-316 (Networks), 321-323 (DBMS), 331-333 (OS), 341-343 (DS)
--   questions: 444...413-428 (Networks 413-416, DBMS 421-424, OS 431-434, DS 441-444)
--              + 444...417-420 (Networks extra), 425-428 etc. — 48 total
--   quizzes : 555...514-516 (Networks), 521-523 (DBMS), 531-533 (OS), 541-543 (DS)
--   quiz_questions: 666...613-...

-- ------------------------------------------------------------------
-- 1) Topics (12) — 3 per remaining subject
-- ------------------------------------------------------------------
INSERT INTO topics (id, subject_id, name, description, difficulty, display_order, is_active, created_at, updated_at) VALUES
-- Computer Networks
('22222222-2222-2222-2222-222222222214', '11111111-1111-1111-1111-111111111102', 'Networking Fundamentals', 'Types of networks, topologies, transmission modes, and the role of protocols in enabling communication between hosts.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222215', '11111111-1111-1111-1111-111111111102', 'OSI & TCP-IP Models', 'The seven-layer OSI model and the four-layer TCP/IP model, encapsulation, and how each layer maps to real protocols.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222216', '11111111-1111-1111-1111-111111111102', 'IP Addressing & Routing', 'IPv4 addressing, subnet masks, CIDR, NAT, and how routers forward packets using routing tables.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS
('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111103', 'Database Fundamentals', 'What a database and DBMS are, advantages over file systems, data abstraction, and the three-schema architecture.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111103', 'Relational Model & Keys', 'Relations, tuples, attributes, primary/foreign/candidate keys, and integrity constraints that keep data consistent.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111103', 'SQL & Transactions', 'Core SQL (DDL/DML), ACID properties, isolation levels, and how transactions protect concurrent access.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Operating Systems
('22222222-2222-2222-2222-222222222231', '11111111-1111-1111-1111-111111111104', 'OS Fundamentals', 'Roles of an operating system, types of OS, system calls, and the boundary between user and kernel mode.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222232', '11111111-1111-1111-1111-111111111104', 'Processes & Threads', 'Process control blocks, states, scheduling, and the trade-offs between processes and threads.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222233', '11111111-1111-1111-1111-111111111104', 'Memory Management', 'Paging, segmentation, virtual memory, TLB, and how the OS isolates and protects process address spaces.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures
('22222222-2222-2222-2222-222222222241', '11111111-1111-1111-1111-111111111105', 'Complexity & Arrays', 'Big-O notation, array layout, dynamic arrays, and the cost of insertion, deletion, and access.', 'EASY', 1, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222242', '11111111-1111-1111-1111-111111111105', 'Stacks & Queues', 'LIFO stacks and FIFO queues, their array and linked implementations, and classic applications like parsing and BFS.', 'EASY', 2, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('22222222-2222-2222-2222-222222222243', '11111111-1111-1111-1111-111111111105', 'Trees & Graphs', 'Binary trees, BSTs, traversals, heaps, and graph representations (adjacency list/matrix) with BFS/DFS.', 'MEDIUM', 3, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 2) Lessons (12) — 1 per new topic, CURATED
-- ------------------------------------------------------------------
INSERT INTO lessons (id, topic_id, title, content, summary, difficulty, source_type, is_active, created_at, updated_at) VALUES
-- Networks
('33333333-3333-3333-3333-333333333314', '22222222-2222-2222-2222-222222222214', 'Networking Fundamentals — The Connected World',
'Networks connect hosts so they can exchange data. A LAN covers a single building, a WAN spans cities, and the Internet is a network of networks. Topologies like star, mesh, and bus describe how links are arranged; star dominates today because a single cable failure isolates only one host.

Transmission can be simplex (one-way), half-duplex (both ways, one at a time), or full-duplex (simultaneous). Protocols are the rules that make communication possible — without a shared protocol, bytes on a wire are meaningless. Layering lets each protocol focus on one concern while relying on the layers below.',
'LAN/WAN/Internet, star/mesh/bus topologies, simplex/half/full-duplex, and why protocols and layering make networks possible.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333315', '22222222-2222-2222-2222-222222222215', 'OSI & TCP-IP — Layered Thinking',
'The OSI model has seven layers: Physical, Data Link, Network, Transport, Session, Presentation, Application. TCP/IP collapses this to four: Link, Internet, Transport, Application. Each layer adds a header (encapsulation) on send and strips it on receive, so an HTTP request travels down through TCP, IP, and Ethernet, then up the same stack on the peer.

A common mistake is to memorize layer numbers without understanding separation of concerns. The Network layer moves packets between hosts, Transport provides end-to-end reliability or speed, and Application defines the semantics (HTTP, DNS, SMTP). When debugging, ask which layer failed: no link (L1/L2), no route (L3), port closed (L4), or malformed request (L7).',
'Seven OSI layers vs four TCP/IP layers, encapsulation on send and decapsulation on receive, and which layer to blame when debugging.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333316', '22222222-2222-2222-2222-222222222216', 'IP Addressing & Routing — Where Packets Go',
'An IPv4 address is 32 bits, written as four octets like 192.168.1.10, plus a subnet mask that splits network and host parts. CIDR writes this as 192.168.1.0/24, meaning 24 network bits and 8 host bits — 254 usable hosts.

Routers forward packets by longest-prefix match against a routing table. If no route matches, the packet is dropped or sent to a default gateway. NAT lets many private hosts share one public IP by rewriting addresses at the border. Subnetting is not about saving addresses alone; it is about containment — a misconfigured mask can isolate a whole department.',
'IPv4 octets, subnet masks, CIDR, longest-prefix match, default gateways, and NAT sharing one public IP.',
'MEDIUM', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS
('33333333-3333-3333-3333-333333333321', '22222222-2222-2222-2222-222222222221', 'Database Fundamentals — From Files to DBMS',
'Before DBMS, applications owned files and duplicated logic for consistency, recovery, and concurrency. A DBMS centralizes data, enforces structure, and guarantees properties that files cannot.

Data abstraction has three levels: physical (how bytes are stored), logical (tables and types), and view (what each application sees). The three-schema architecture isolates applications from storage changes. The payoff is not just convenience — a single recovery log can restore the entire database after a crash, which file-per-application could never do reliably.',
'File-system limits, three levels of data abstraction, and why a central DBMS beats per-application files for consistency and recovery.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333322', '22222222-2222-2222-2222-222222222222', 'Relational Model & Keys — Structure and Constraints',
'A relation is a table with a header (attributes) and a body (tuples). A primary key uniquely identifies a row; a foreign key points at a primary key elsewhere, creating a link. Candidate keys are all minimal unique sets; one is chosen as primary.

Integrity constraints are not suggestions. Entity integrity forbids null primary keys, referential integrity forbids dangling foreign keys, and domain integrity restricts values (e.g., age >= 0). Violate these and the database is no longer a faithful model of the real world, no matter how fast the queries are.',
'Relations/tuples/attributes, primary/foreign/candidate keys, and entity/referential/domain integrity as non-negotiable rules.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333323', '22222222-2222-2222-2222-222222222223', 'SQL & Transactions — Language and Correctness',
'SQL splits into DDL (CREATE, ALTER) and DML (SELECT, INSERT, UPDATE, DELETE). A transaction groups statements so they are atomic: all commit or all roll back. ACID captures this — Atomicity, Consistency, Isolation, Durability.

Isolation levels trade correctness for concurrency. Read Committed sees only committed data; Serializable behaves as if transactions ran one by one, at the cost of blocking. Choosing an isolation level is not about performance tweaks; it is about which anomalies (dirty reads, phantom reads) the application can tolerate.',
'DDL vs DML, transactions as atomic units, ACID, and isolation levels trading correctness for concurrency.',
'MEDIUM', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- OS
('33333333-3333-3333-3333-333333333331', '22222222-2222-2222-2222-222222222231', 'OS Fundamentals — The Supervisor',
'An operating system multiplexes hardware among programs. It provides processes, files, and communication, and it enforces isolation so one program cannot corrupt another. Types range from batch and time-sharing to real-time and embedded, but all must handle the same tensions: fairness vs throughput, latency vs utilization.

System calls are the narrow gate between user and kernel mode. A program in user mode cannot touch hardware directly; it traps into the kernel, which validates, performs, and returns. This boundary is not bureaucracy — it is the only thing preventing a buggy loop from overwriting the disk.',
'Multiplexing, OS types, and system calls as the gated boundary between user and kernel mode.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333332', '22222222-2222-2222-2222-222222222232', 'Processes & Threads — Units of Execution',
'A process is an address space plus one or more threads, a program counter, and OS bookkeeping (PCB). Threads of the same process share memory and files, so context switches between them are cheaper than between processes, but they must synchronize to avoid races.

Scheduling decides which ready thread runs. Metrics include turnaround, waiting, and response time. No single algorithm wins everywhere: FCFS is fair but convoy-prone, SJF is optimal for average waiting but needs prediction, round-robin bounds response time at the cost of throughput. The art is matching the algorithm to the workload.',
'Process vs thread, PCB/states, and scheduling trade-offs (FCFS, SJF, round-robin).',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222233', 'Memory Management — Isolation and Illusion',
'Virtual memory gives each process the illusion of a large, private address space. Paging splits memory into fixed frames and maps virtual pages via a page table; TLB caches translations so the common case is fast. Segmentation uses variable-sized segments that mirror program structure but complicates allocation.

Without virtual memory, a process could read another process''s bytes directly. With it, the MMU translates every access, and a stray pointer faults instead of corrupting. Fragmentation, page faults, and replacement (LRU, Clock) are not edge cases — they are the steady state the OS must handle.',
'Virtual memory illusion, paging/segmentation, TLB, and why translation protects process isolation.',
'MEDIUM', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures
('33333333-3333-3333-3333-333333333341', '22222222-2222-2222-2222-222222222241', 'Complexity & Arrays — Costs First',
'Big-O describes growth, not exact time. O(1) is constant, O(log n) halves, O(n) scans, O(n log n) sorts, O(n²) is often too slow at scale. An array stores elements contiguously, so access by index is O(1), but insertion in the middle is O(n) because elements must shift.

A dynamic array (ArrayList/vector) doubles its capacity when full, so amortized push is O(1) despite occasional O(n) copies. The lesson is not to memorize tables, but to predict: will this structure still be fast when n grows 100x?',
'Big-O growth, array O(1) access vs O(n) insertion, and dynamic array amortized O(1) via doubling.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333342', '22222222-2222-2222-2222-222222222242', 'Stacks & Queues — LIFO and FIFO',
'A stack is LIFO: push and pop at one end, perfect for call frames, undo, and bracket matching. A queue is FIFO: enqueue at the tail, dequeue at the head, used for scheduling and BFS. Both can be built on arrays or linked nodes; the interface matters more than the implementation.

A common pitfall is to use a list as a queue by removing from index 0, which is O(n) per operation. A proper queue uses a circular buffer or linked nodes so dequeue stays O(1). Recognizing LIFO vs FIFO in a problem statement is often the first step to the right structure.',
'LIFO vs FIFO, array/linked implementations, and why a list is a poor queue.',
'EASY', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('33333333-3333-3333-3333-333333333343', '22222222-2222-2222-2222-222222222243', 'Trees & Graphs — Branching Structures',
'A binary tree has at most two children per node; a BST orders left < parent < right, so search is O(log n) when balanced, O(n) when skewed. Traversals (inorder, preorder, postorder) visit the same nodes in different orders, which matters for expression evaluation and serialization.

Graphs generalize trees with arbitrary edges. Representations trade space for speed: adjacency matrix is O(V²) but O(1) edge test, adjacency list is O(V+E) and iterates neighbors efficiently. BFS explores level by level with a queue, DFS dives with a stack or recursion; the choice shapes the order in which solutions are found.',
'Binary trees, BST balance, traversals, adjacency matrix vs list, BFS queue / DFS stack.',
'MEDIUM', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 3) Questions (48) — 4 per new topic, MCQ, CURATED
-- ------------------------------------------------------------------
INSERT INTO questions (id, topic_id, question_text, question_type, difficulty, options_json, correct_answer, explanation, source_type, is_active, created_at, updated_at) VALUES
-- Networks: Fundamentals 214
('44444444-4444-4444-4444-444444444413', '22222222-2222-2222-2222-222222222214', 'Which topology isolates a cable failure to one host?', 'MCQ', 'EASY', '{"options": ["Star", "Bus", "Ring", "Full mesh without switching"]}', 'Star', 'Star connects every host to a central switch; a single link failure affects only that host.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444414', '22222222-2222-2222-2222-222222222214', 'What does full-duplex allow?', 'MCQ', 'EASY', '{"options": ["Simultaneous two-way transmission", "One-way only", "Two-way, one direction at a time", "No transmission"]}', 'Simultaneous two-way transmission', 'Full-duplex carries traffic both ways at once; half-duplex alternates.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444415', '22222222-2222-2222-2222-222222222214', 'Why layer protocols?', 'MCQ', 'EASY', '{"options": ["Each layer handles one concern, relying on the layers below", "To make headers larger", "To avoid any specification", "Because one layer is always sufficient"]}', 'Each layer handles one concern, relying on the layers below', 'Layering separates concerns; a layer uses the service of the layer below without knowing its internals.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444416', '22222222-2222-2222-2222-222222222214', 'Which is a LAN example?', 'MCQ', 'EASY', '{"options": ["Office floor network", "Transcontinental backbone", "The Internet", "Geostationary satellite network"]}', 'Office floor network', 'LAN spans a single site; WAN spans cities, the Internet is global.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Networks: OSI & TCP-IP 215
('44444444-4444-4444-4444-444444444417', '22222222-2222-2222-2222-222222222215', 'How many layers does OSI have vs TCP/IP?', 'MCQ', 'EASY', '{"options": ["7 vs 4", "4 vs 7", "5 vs 5", "7 vs 7"]}', '7 vs 4', 'OSI has 7, TCP/IP collapses to 4 (Link, Internet, Transport, Application).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444418', '22222222-2222-2222-2222-222222222215', 'What happens to headers on send?', 'MCQ', 'EASY', '{"options": ["Each layer adds a header (encapsulation)", "Headers are removed", "Only the application adds a header", "Headers are encrypted and never added"]}', 'Each layer adds a header (encapsulation)', 'Sending encapsulates: Application → Transport → Internet → Link, each adding a header.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444419', '22222222-2222-2222-2222-222222222215', 'Which layer moves packets between hosts?', 'MCQ', 'EASY', '{"options": ["Network (Internet) layer", "Physical layer only", "Session layer", "Presentation layer"]}', 'Network (Internet) layer', 'Network/Internet layer handles host-to-host routing; Transport is end-to-end.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444420', '22222222-2222-2222-2222-222222222215', 'When debugging, port closed indicates failure at which layer?', 'MCQ', 'EASY', '{"options": ["Transport (L4)", "Physical (L1)", "Network (L3)", "Data Link (L2)"]}', 'Transport (L4)', 'Port reachability is a Transport-layer concern (TCP/UDP).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Networks: IP & Routing 216
('44444444-4444-4444-4444-444444444421', '22222222-2222-2222-2222-222222222216', 'What does CIDR /24 mean?', 'MCQ', 'MEDIUM', '{"options": ["24 network bits, 8 host bits", "24 host bits, 8 network bits", "24 total bits", "24 addresses"]}', '24 network bits, 8 host bits', '/24 leaves 8 host bits → 254 usable hosts.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444422', '22222222-2222-2222-2222-222222222216', 'How does a router choose a route?', 'MCQ', 'MEDIUM', '{"options": ["Longest-prefix match", "Shortest header", "First alphabetically", "Random"]}', 'Longest-prefix match', 'Routers pick the most specific (longest) matching prefix.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444423', '22222222-2222-2222-2222-222222222216', 'What does NAT do?', 'MCQ', 'MEDIUM', '{"options": ["Shares one public IP among many private hosts", "Assigns every host a public IP", "Encrypts DNS queries", "Removes IP headers"]}', 'Shares one public IP among many private hosts', 'NAT rewrites private addresses to a shared public address at the border.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444424', '22222222-2222-2222-2222-222222222216', 'A mask 255.255.255.0 leaves how many host bits?', 'MCQ', 'MEDIUM', '{"options": ["8", "16", "24", "32"]}', '8', '255.255.255.0 = /24 → 8 host bits.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS: Fundamentals 221
('44444444-4444-4444-4444-444444444431', '22222222-2222-2222-2222-222222222221', 'What problem does a DBMS solve vs files?', 'MCQ', 'EASY', '{"options": ["Centralizes data, enforces consistency, recovery, and concurrency", "Makes data permanently inconsistent", "Removes the need for any queries", "Stores data only in RAM"]}', 'Centralizes data, enforces consistency, recovery, and concurrency', 'DBMS provides structure, guarantees, and recovery that per-application files cannot.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444432', '22222222-2222-2222-2222-222222222221', 'Which describes the three-schema architecture?', 'MCQ', 'EASY', '{"options": ["Physical, logical, view", "Network, transport, application", "Primary, foreign, candidate", "Select, insert, update"]}', 'Physical, logical, view', 'Physical is storage, logical is tables, view is per-application.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444433', '22222222-2222-2222-2222-222222222221', 'What can a single DBMS log do after a crash?', 'MCQ', 'EASY', '{"options": ["Restore the entire database", "Only restore one file", "Nothing", "Delete all data"]}', 'Restore the entire database', 'A central log enables full recovery, unlike file-per-application.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444434', '22222222-2222-2222-2222-222222222221', 'Which is NOT a DBMS advantage?', 'MCQ', 'EASY', '{"options": ["Automatic enforcement of constraints and recovery", "Duplicated per-application recovery logic", "Centralized concurrency control", "Data abstraction"]}', 'Duplicated per-application recovery logic', 'Duplicated logic is the file-system problem, not a DBMS advantage.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS: Relational Model 222
('44444444-4444-4444-4444-444444444435', '22222222-2222-2222-2222-222222222222', 'What uniquely identifies a tuple?', 'MCQ', 'EASY', '{"options": ["Primary key", "View", "Index", "Transaction"]}', 'Primary key', 'Primary key is the chosen minimal unique identifier.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444436', '22222222-2222-2222-2222-222222222222', 'What does a foreign key point to?', 'MCQ', 'EASY', '{"options": ["A primary key elsewhere", "A view definition", "A transaction log", "An index file"]}', 'A primary key elsewhere', 'Foreign key references a primary key in another relation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444437', '22222222-2222-2222-2222-222222222222', 'Which integrity forbids null primary keys?', 'MCQ', 'EASY', '{"options": ["Entity integrity", "Referential integrity", "Domain integrity", "ACID"]}', 'Entity integrity', 'Entity integrity requires every primary key to be non-null.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444438', '22222222-2222-2222-2222-222222222222', 'Which forbids dangling foreign keys?', 'MCQ', 'EASY', '{"options": ["Referential integrity", "Entity integrity", "Domain integrity", "Two-phase commit"]}', 'Referential integrity', 'Referential integrity guarantees every foreign key value exists as a primary key.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS: SQL & Transactions 223
('44444444-4444-4444-4444-444444444439', '22222222-2222-2222-2222-222222222223', 'Which SQL group creates tables?', 'MCQ', 'MEDIUM', '{"options": ["DDL", "DML", "DCL", "TCL"]}', 'DDL', 'DDL (CREATE, ALTER, DROP) defines structure.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444440', '22222222-2222-2222-2222-222222222223', 'What does a transaction guarantee?', 'MCQ', 'MEDIUM', '{"options": ["All statements commit or all roll back (atomicity)", "Only the first statement commits", "Statements are always concurrent", "No guarantees"]}', 'All statements commit or all roll back (atomicity)', 'Transactions are atomic units.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444441', '22222222-2222-2222-2222-222222222223', 'Which isolation behaves as if transactions ran one by one?', 'MCQ', 'MEDIUM', '{"options": ["Serializable", "Read Uncommitted", "Read Committed", "Eventual"]}', 'Serializable', 'Serializable is the strongest, most blocking level.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444442', '22222222-2222-2222-2222-222222222223', 'Dirty reads are prevented at which level and above?', 'MCQ', 'MEDIUM', '{"options": ["Read Committed and above", "Read Uncommitted only", "Serializable only", "Never"]}', 'Read Committed and above', 'Read Committed sees only committed data; Read Uncommitted can see dirty reads.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- OS: Fundamentals 231
('44444444-4444-4444-4444-444444444451', '22222222-2222-2222-2222-222222222231', 'What does an OS multiplex?', 'MCQ', 'EASY', '{"options": ["Hardware among programs", "Only the keyboard", "Only the network", "Nothing"]}', 'Hardware among programs', 'OS shares CPU, memory, and I/O among programs with isolation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444452', '22222222-2222-2222-2222-222222222231', 'What is a system call?', 'MCQ', 'EASY', '{"options": ["A gated trap from user to kernel mode", "A normal function call", "A hardware interrupt only", "A network packet"]}', 'A gated trap from user to kernel mode', 'System calls are the narrow, validated gate to privileged operations.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444453', '22222222-2222-2222-2222-222222222231', 'Why prevent user programs from touching hardware directly?', 'MCQ', 'EASY', '{"options": ["To stop a buggy loop from overwriting the disk", "To make programs slower", "To save power only", "There is no reason"]}', 'To stop a buggy loop from overwriting the disk', 'Isolation is the only thing preventing corruption.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444454', '22222222-2222-2222-2222-222222222231', 'Which is a time-sharing OS example?', 'MCQ', 'EASY', '{"options": ["Multics/Unix-like", "Single-purpose batch only", "No OS", "Firmware only"]}', 'Multics/Unix-like', 'Time-sharing multiplexes interactive users.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- OS: Processes & Threads 232
('44444444-4444-4444-4444-444444444455', '22222222-2222-2222-2222-222222222232', 'What does a PCB store?', 'MCQ', 'EASY', '{"options": ["Process state, registers, scheduling info", "Only the program code", "Only the file name", "Nothing"]}', 'Process state, registers, scheduling info', 'PCB is the OS bookkeeping for a process.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444456', '22222222-2222-2222-2222-222222222232', 'Why are thread switches cheaper than process switches?', 'MCQ', 'EASY', '{"options": ["Threads share address space and files", "Threads use more memory", "Processes are always single-threaded", "There is no difference"]}', 'Threads share address space and files', 'Shared state avoids flushing address spaces.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444457', '22222222-2222-2222-2222-222222222232', 'Which metric bounds interactive response?', 'MCQ', 'EASY', '{"options": ["Response time (round-robin)", "Turnaround only", "Throughput only", "No metric"]}', 'Response time (round-robin)', 'Round-robin bounds response time at cost of throughput.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444458', '22222222-2222-2222-2222-222222222232', 'Which scheduling is convoy-prone but fair?', 'MCQ', 'EASY', '{"options": ["FCFS", "SJF", "Round-robin", "Priority"]}', 'FCFS', 'FCFS (first-come first-served) suffers convoy effect.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- OS: Memory 233
('44444444-4444-4444-4444-444444444459', '22222222-2222-2222-2222-222222222233', 'What gives each process a private address illusion?', 'MCQ', 'MEDIUM', '{"options": ["Virtual memory", "Physical memory only", "No memory", "Registers only"]}', 'Virtual memory', 'Virtual memory via page tables and MMU provides isolation.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444460', '22222222-2222-2222-2222-222222222233', 'What caches page translations?', 'MCQ', 'MEDIUM', '{"options": ["TLB", "L1 cache only", "Disk", "NIC"]}', 'TLB', 'TLB (translation lookaside buffer) caches page table entries.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444461', '22222222-2222-2222-2222-222222222233', 'What happens on a stray pointer without virtual memory?', 'MCQ', 'MEDIUM', '{"options": ["Corrupts another process", "Always faults", "Is always safe", "Nothing"]}', 'Corrupts another process', 'Without translation, a stray write corrupts; with it, it faults.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444462', '22222222-2222-2222-2222-222222222233', 'Which replacement is considered steady state?', 'MCQ', 'MEDIUM', '{"options": ["LRU/Clock page replacement", "No replacement", "Single page", "No paging"]}', 'LRU/Clock page replacement', 'Replacement is the steady state, not an edge case.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures: Complexity & Arrays 241
('44444444-4444-4444-4444-444444444471', '22222222-2222-2222-2222-222222222241', 'What does O(n log n) typically describe?', 'MCQ', 'EASY', '{"options": ["Sorting", "Constant access", "Halving search", "Quadratic scan"]}', 'Sorting', 'Efficient sorts like mergesort are O(n log n).', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444472', '22222222-2222-2222-2222-222222222241', 'Array access by index is?', 'MCQ', 'EASY', '{"options": ["O(1)", "O(n)", "O(log n)", "O(n²)"]}', 'O(1)', 'Contiguous storage gives constant-time indexing.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444473', '22222222-2222-2222-2222-222222222241', 'Insertion in the middle of an array is?', 'MCQ', 'EASY', '{"options": ["O(n) due to shifting", "O(1)", "O(log n)", "O(0)"]}', 'O(n) due to shifting', 'Elements after the insertion point must shift.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444474', '22222222-2222-2222-2222-222222222241', 'Dynamic array amortized push is O(1) because?', 'MCQ', 'EASY', '{"options": ["Capacity doubles when full", "It never copies", "It is always O(n)", "It uses a linked list"]}', 'Capacity doubles when full', 'Doubling yields amortized O(1) despite occasional O(n) copy.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures: Stacks & Queues 242
('44444444-4444-4444-4444-444444444475', '22222222-2222-2222-2222-222222222242', 'Stack is?', 'MCQ', 'EASY', '{"options": ["LIFO", "FIFO", "Random", "Sorted"]}', 'LIFO', 'Stack: last-in, first-out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444476', '22222222-2222-2222-2222-222222222242', 'Queue is?', 'MCQ', 'EASY', '{"options": ["FIFO", "LIFO", "Random", "Sorted"]}', 'FIFO', 'Queue: first-in, first-out.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444477', '22222222-2222-2222-2222-222222222242', 'Using a list with remove(0) as a queue is?', 'MCQ', 'EASY', '{"options": ["O(n) per dequeue — poor", "O(1) — ideal", "O(log n)", "O(0)"]}', 'O(n) per dequeue — poor', 'Removing from index 0 shifts all elements.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444478', '22222222-2222-2222-2222-222222222242', 'Stack is used for?', 'MCQ', 'EASY', '{"options": ["Call frames, undo, bracket matching", "Scheduling BFS", "Sorting only", "Nothing"]}', 'Call frames, undo, bracket matching', 'Stacks match LIFO use cases.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures: Trees & Graphs 243
('44444444-4444-4444-4444-444444444479', '22222222-2222-2222-2222-222222222243', 'BST search when balanced is?', 'MCQ', 'MEDIUM', '{"options": ["O(log n)", "O(n)", "O(1)", "O(n²)"]}', 'O(log n)', 'Balanced BST search halves each step.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444480', '22222222-2222-2222-2222-222222222243', 'Inorder traversal of BST yields?', 'MCQ', 'MEDIUM', '{"options": ["Sorted order", "Random order", "Reverse order", "No order"]}', 'Sorted order', 'Inorder visits left, node, right → sorted.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444481', '22222222-2222-2222-2222-222222222243', 'Adjacency list space is?', 'MCQ', 'MEDIUM', '{"options": ["O(V+E)", "O(V²)", "O(1)", "O(E²)"]}', 'O(V+E)', 'List stores vertices plus edges.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('44444444-4444-4444-4444-444444444482', '22222222-2222-2222-2222-222222222243', 'BFS uses?', 'MCQ', 'MEDIUM', '{"options": ["Queue", "Stack", "Array only", "Heap"]}', 'Queue', 'BFS level-by-level via queue; DFS via stack.', 'CURATED', TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 4) Quizzes (12) — 1 per new topic, CURATED
-- ------------------------------------------------------------------
INSERT INTO quizzes (id, topic_id, title, description, difficulty, source_type, time_limit_seconds, is_active, created_at, updated_at) VALUES
-- Networks
('55555555-5555-5555-5555-555555555514', '22222222-2222-2222-2222-222222222214', 'Networking Fundamentals Challenge', 'Apply topology, duplex, layering, and LAN concepts.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555515', '22222222-2222-2222-2222-222222222215', 'OSI & TCP-IP Challenge', 'Prove OSI vs TCP/IP, encapsulation, and layer debugging.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555516', '22222222-2222-2222-2222-222222222216', 'IP Addressing & Routing Challenge', 'Subnet, CIDR, longest-prefix, and NAT reasoning.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- DBMS
('55555555-5555-5555-5555-555555555521', '22222222-2222-2222-2222-222222222221', 'Database Fundamentals Challenge', 'DBMS advantages, three-schema, recovery.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555522', '22222222-2222-2222-2222-222222222222', 'Relational Model & Keys Challenge', 'Keys and integrity constraints.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555523', '22222222-2222-2222-2222-222222222223', 'SQL & Transactions Challenge', 'DDL/DML, ACID, isolation.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- OS
('55555555-5555-5555-5555-555555555531', '22222222-2222-2222-2222-222222222231', 'OS Fundamentals Challenge', 'Multiplexing, system calls, isolation.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555532', '22222222-2222-2222-2222-222222222232', 'Processes & Threads Challenge', 'PCB, thread vs process, scheduling.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555533', '22222222-2222-2222-2222-222222222233', 'Memory Management Challenge', 'Virtual memory, paging, TLB.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
-- Data Structures
('55555555-5555-5555-5555-555555555541', '22222222-2222-2222-2222-222222222241', 'Complexity & Arrays Challenge', 'Big-O, array costs, dynamic arrays.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555542', '22222222-2222-2222-2222-222222222242', 'Stacks & Queues Challenge', 'LIFO/FIFO, queue implementation.', 'EASY', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('55555555-5555-5555-5555-555555555543', '22222222-2222-2222-2222-222222222243', 'Trees & Graphs Challenge', 'BST, traversals, adjacency, BFS.', 'MEDIUM', 'CURATED', NULL, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- ------------------------------------------------------------------
-- 5) QuizQuestions (48) — 4 per new quiz, ordered 1..4
-- ------------------------------------------------------------------
INSERT INTO quiz_questions (id, quiz_id, question_id, question_order, created_at) VALUES
-- Networks 214 -> quiz 514
('66666666-6666-6666-6666-666666666613', '55555555-5555-5555-5555-555555555514', '44444444-4444-4444-4444-444444444413', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666614', '55555555-5555-5555-5555-555555555514', '44444444-4444-4444-4444-444444444414', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666615', '55555555-5555-5555-5555-555555555514', '44444444-4444-4444-4444-444444444415', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666616', '55555555-5555-5555-5555-555555555514', '44444444-4444-4444-4444-444444444416', 4, CURRENT_TIMESTAMP),
-- Networks 215 -> quiz 515
('66666666-6666-6666-6666-666666666617', '55555555-5555-5555-5555-555555555515', '44444444-4444-4444-4444-444444444417', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666618', '55555555-5555-5555-5555-555555555515', '44444444-4444-4444-4444-444444444418', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666619', '55555555-5555-5555-5555-555555555515', '44444444-4444-4444-4444-444444444419', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666620', '55555555-5555-5555-5555-555555555515', '44444444-4444-4444-4444-444444444420', 4, CURRENT_TIMESTAMP),
-- Networks 216 -> quiz 516
('66666666-6666-6666-6666-666666666621', '55555555-5555-5555-5555-555555555516', '44444444-4444-4444-4444-444444444421', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666622', '55555555-5555-5555-5555-555555555516', '44444444-4444-4444-4444-444444444422', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666623', '55555555-5555-5555-5555-555555555516', '44444444-4444-4444-4444-444444444423', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666624', '55555555-5555-5555-5555-555555555516', '44444444-4444-4444-4444-444444444424', 4, CURRENT_TIMESTAMP),
-- DBMS 221 -> quiz 521
('66666666-6666-6666-6666-666666666625', '55555555-5555-5555-5555-555555555521', '44444444-4444-4444-4444-444444444431', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666626', '55555555-5555-5555-5555-555555555521', '44444444-4444-4444-4444-444444444432', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666627', '55555555-5555-5555-5555-555555555521', '44444444-4444-4444-4444-444444444433', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666628', '55555555-5555-5555-5555-555555555521', '44444444-4444-4444-4444-444444444434', 4, CURRENT_TIMESTAMP),
-- DBMS 222 -> quiz 522
('66666666-6666-6666-6666-666666666629', '55555555-5555-5555-5555-555555555522', '44444444-4444-4444-4444-444444444435', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666630', '55555555-5555-5555-5555-555555555522', '44444444-4444-4444-4444-444444444436', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666631', '55555555-5555-5555-5555-555555555522', '44444444-4444-4444-4444-444444444437', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666632', '55555555-5555-5555-5555-555555555522', '44444444-4444-4444-4444-444444444438', 4, CURRENT_TIMESTAMP),
-- DBMS 223 -> quiz 523
('66666666-6666-6666-6666-666666666633', '55555555-5555-5555-5555-555555555523', '44444444-4444-4444-4444-444444444439', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666634', '55555555-5555-5555-5555-555555555523', '44444444-4444-4444-4444-444444444440', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666635', '55555555-5555-5555-5555-555555555523', '44444444-4444-4444-4444-444444444441', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666636', '55555555-5555-5555-5555-555555555523', '44444444-4444-4444-4444-444444444442', 4, CURRENT_TIMESTAMP),
-- OS 231 -> quiz 531
('66666666-6666-6666-6666-666666666637', '55555555-5555-5555-5555-555555555531', '44444444-4444-4444-4444-444444444451', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666638', '55555555-5555-5555-5555-555555555531', '44444444-4444-4444-4444-444444444452', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666639', '55555555-5555-5555-5555-555555555531', '44444444-4444-4444-4444-444444444453', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666640', '55555555-5555-5555-5555-555555555531', '44444444-4444-4444-4444-444444444454', 4, CURRENT_TIMESTAMP),
-- OS 232 -> quiz 532
('66666666-6666-6666-6666-666666666641', '55555555-5555-5555-5555-555555555532', '44444444-4444-4444-4444-444444444455', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666642', '55555555-5555-5555-5555-555555555532', '44444444-4444-4444-4444-444444444456', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666643', '55555555-5555-5555-5555-555555555532', '44444444-4444-4444-4444-444444444457', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666644', '55555555-5555-5555-5555-555555555532', '44444444-4444-4444-4444-444444444458', 4, CURRENT_TIMESTAMP),
-- OS 233 -> quiz 533
('66666666-6666-6666-6666-666666666645', '55555555-5555-5555-5555-555555555533', '44444444-4444-4444-4444-444444444459', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666646', '55555555-5555-5555-5555-555555555533', '44444444-4444-4444-4444-444444444460', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666647', '55555555-5555-5555-5555-555555555533', '44444444-4444-4444-4444-444444444461', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666648', '55555555-5555-5555-5555-555555555533', '44444444-4444-4444-4444-444444444462', 4, CURRENT_TIMESTAMP),
-- DS 241 -> quiz 541
('66666666-6666-6666-6666-666666666649', '55555555-5555-5555-5555-555555555541', '44444444-4444-4444-4444-444444444471', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666650', '55555555-5555-5555-5555-555555555541', '44444444-4444-4444-4444-444444444472', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666651', '55555555-5555-5555-5555-555555555541', '44444444-4444-4444-4444-444444444473', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666652', '55555555-5555-5555-5555-555555555541', '44444444-4444-4444-4444-444444444474', 4, CURRENT_TIMESTAMP),
-- DS 242 -> quiz 542
('66666666-6666-6666-6666-666666666653', '55555555-5555-5555-5555-555555555542', '44444444-4444-4444-4444-444444444475', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666654', '55555555-5555-5555-5555-555555555542', '44444444-4444-4444-4444-444444444476', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666655', '55555555-5555-5555-5555-555555555542', '44444444-4444-4444-4444-444444444477', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666656', '55555555-5555-5555-5555-555555555542', '44444444-4444-4444-4444-444444444478', 4, CURRENT_TIMESTAMP),
-- DS 243 -> quiz 543
('66666666-6666-6666-6666-666666666657', '55555555-5555-5555-5555-555555555543', '44444444-4444-4444-4444-444444444479', 1, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666658', '55555555-5555-5555-5555-555555555543', '44444444-4444-4444-4444-444444444480', 2, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666659', '55555555-5555-5555-5555-555555555543', '44444444-4444-4444-4444-444444444481', 3, CURRENT_TIMESTAMP),
('66666666-6666-6666-6666-666666666660', '55555555-5555-5555-5555-555555555543', '44444444-4444-4444-4444-444444444482', 4, CURRENT_TIMESTAMP);
