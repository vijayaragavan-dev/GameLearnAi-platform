"""Labeled synthetic fixtures for Gate 21 corpus tests.

All IDs use the obvious ``g21-fixture`` prefix — never real corpus
content, never learner data, never presented as live evidence. No
database, no network, no LLM calls.
"""

from __future__ import annotations

FIX = "g21-fixture"


def base_tables():
    return {
        "subjects": [{
            "id": f"{FIX}-subject-1", "name": "Arithmetic",
            "description": "Numbers and operations.",
            "is_active": 1,
        }],
        "units": [{
            "id": f"{FIX}-unit-1", "subject_id": f"{FIX}-subject-1",
            "name": "Basics", "description": "First steps.",
            "is_active": 1,
        }],
        "topics": [{
            "id": f"{FIX}-topic-1", "subject_id": f"{FIX}-subject-1",
            "unit_id": f"{FIX}-unit-1", "name": "Fractions",
            "description": "Parts of a whole number.",
            "difficulty": "EASY", "is_active": 1,
            "updated_at": "2026-01-01T00:00:00",
        }],
        "lessons": [{
            "id": f"{FIX}-lesson-1", "topic_id": f"{FIX}-topic-1",
            "subject_id": f"{FIX}-subject-1", "unit_id": f"{FIX}-unit-1",
            "title": "Introducing halves",
            "content": "A half is one of two equal parts.\n\n"
                       "Two halves make a whole.",
            "summary": "Halves in brief.",
            "difficulty": "EASY", "source_type": "CURATED",
            "is_active": 1, "updated_at": "2026-01-02T00:00:00",
        }],
        "questions": [{
            "id": f"{FIX}-question-1", "topic_id": f"{FIX}-topic-1",
            "subject_id": f"{FIX}-subject-1", "unit_id": f"{FIX}-unit-1",
            "question_text": "How many halves make a whole?",
            "options": '["One", "Two"]',
            "explanation": "Two halves make one whole.",
            "difficulty": "EASY", "source_type": "CURATED",
            "is_active": 1, "updated_at": "2026-01-03T00:00:00",
        }],
    }
