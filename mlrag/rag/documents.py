"""RAG document contract (GATE 6, PHASE 2).

One retrievable unit grounded in exactly one authoritative source row.
IDs and metadata are taken from the source — never invented.  Fields the
current schema cannot supply are marked unavailable (not fabricated):

  REQUIRED: doc_id, source_table, source_id, text, subject_id, topic_id,
            is_active, citation inputs.
  OPTIONAL (present when the source kind supports it): unit_id, lesson_id,
            question_id, difficulty, content_version (updated_at ISO),
            title, source_type.
  UNAVAILABLE in current schema: explicit content-version numbers,
            embedding vectors, author/syllabus-version stamps, PII (never
            wanted), subject-level topic linkage (subject rows carry no
            topic and are therefore scope labels, not retrievable chunks).
"""

from __future__ import annotations

from dataclasses import dataclass

from mlrag.contracts.common import ContractViolation, Difficulty

APPROVED_SOURCE_TABLES = frozenset({"lessons", "topics", "questions"})

MAX_TEXT_CHARS = 8000


@dataclass(frozen=True)
class RagDocument:
    """A validated, citable retrieval unit.  Frozen: no mutation path."""

    doc_id: str          # stable: f"{source_table}:{source_id}#c{index}"
    source_table: str    # one of APPROVED_SOURCE_TABLES
    source_id: str       # the source row's primary key (verbatim)
    text: str            # verbatim source content (plus labeled context line)
    subject_id: str
    topic_id: str
    is_active: bool
    unit_id: str | None = None
    lesson_id: str | None = None
    question_id: str | None = None
    difficulty: Difficulty | None = None
    content_version: str = "unversioned"  # updated_at ISO when known
    title: str | None = None
    source_type: str | None = None

    def __post_init__(self) -> None:
        if self.source_table not in APPROVED_SOURCE_TABLES:
            raise ContractViolation(
                f"unapproved document source: {self.source_table}")
        for name in ("doc_id", "source_id", "subject_id", "topic_id",
                     "text", "content_version"):
            value = getattr(self, name)
            if not isinstance(value, str) or not value.strip():
                raise ContractViolation(f"{name} must be a non-empty string")
        if not isinstance(self.is_active, bool):
            raise ContractViolation("is_active must be a boolean")
        if len(self.text) > MAX_TEXT_CHARS:
            raise ContractViolation("document text exceeds maximum length")
        expected_prefix = f"{self.source_table}:{self.source_id}#"
        if not self.doc_id.startswith(expected_prefix):
            raise ContractViolation(
                "doc_id must embed its provenance "
                f"(expected prefix {expected_prefix!r})")

    @property
    def citation(self) -> str:
        """Stable citation handle for grounded answers."""
        return f"{self.source_table}:{self.source_id}#{self.doc_id.rsplit('#', 1)[-1]}"
