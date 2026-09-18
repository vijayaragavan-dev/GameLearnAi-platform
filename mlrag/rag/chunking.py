"""Deterministic, content-preserving chunking (GATE 6, PHASE 3).

Strategy: split source text into paragraphs (blank-line separated),
greedily pack paragraphs up to ``max_chars`` preserving order; a single
paragraph longer than the budget is split on sentence boundaries, falling
back to a hard character split only when no sentence boundary exists.
No semantic rewriting, no summarization, no silent deletion: every
non-whitespace input character appears in exactly one chunk, in order.
Each chunk keeps full provenance (source IDs + stable index suffix).
"""

from __future__ import annotations

import re

from .documents import RagDocument

DEFAULT_MAX_CHARS = 1500

_SENTENCE_SPLIT = re.compile(r"(?<=[.!?])\s+")


def _split_paragraphs(text: str) -> list[str]:
    parts = [p.strip() for p in re.split(r"\n\s*\n", text)]
    return [p for p in parts if p]


def _split_long_paragraph(paragraph: str, max_chars: int) -> list[str]:
    sentences = [s.strip() for s in _SENTENCE_SPLIT.split(paragraph) if s.strip()]
    if len(sentences) <= 1:
        return [paragraph[i:i + max_chars]
                for i in range(0, len(paragraph), max_chars)]
    pieces: list[str] = []
    current = ""
    for sentence in sentences:
        if len(sentence) > max_chars:
            if current:
                pieces.append(current)
                current = ""
            pieces.extend(
                sentence[i:i + max_chars]
                for i in range(0, len(sentence), max_chars))
        elif len(current) + 1 + len(sentence) <= max_chars:
            current = f"{current} {sentence}".strip()
        else:
            pieces.append(current)
            current = sentence
    if current:
        pieces.append(current)
    return pieces


def chunk_document_fields(*, source_table: str, source_id: str,
                          subject_id: str, topic_id: str, text: str,
                          is_active: bool, unit_id: str | None = None,
                          lesson_id: str | None = None,
                          question_id: str | None = None,
                          difficulty=None, content_version: str = "unversioned",
                          title: str | None = None,
                          source_type: str | None = None,
                          context_line: str | None = None,
                          max_chars: int = DEFAULT_MAX_CHARS
                          ) -> list[RagDocument]:
    """Chunk one source record's text into validated RagDocuments."""
    if max_chars <= 0:
        raise ValueError("max_chars must be positive")
    paragraphs: list[str] = []
    for paragraph in _split_paragraphs(text):
        if len(paragraph) <= max_chars:
            paragraphs.append(paragraph)
        else:
            paragraphs.extend(_split_long_paragraph(paragraph, max_chars))
    groups: list[str] = []
    current = ""
    for paragraph in paragraphs:
        if not current:
            current = paragraph
        elif len(current) + 2 + len(paragraph) <= max_chars:
            current = f"{current}\n\n{paragraph}"
        else:
            groups.append(current)
            current = paragraph
    if current:
        groups.append(current)
    documents = []
    for index, group in enumerate(groups):
        body = f"{context_line}\n{group}" if context_line else group
        documents.append(RagDocument(
            doc_id=f"{source_table}:{source_id}#c{index}",
            source_table=source_table,
            source_id=source_id,
            text=body,
            subject_id=subject_id,
            topic_id=topic_id,
            is_active=is_active,
            unit_id=unit_id,
            lesson_id=lesson_id,
            question_id=question_id,
            difficulty=difficulty,
            content_version=content_version,
            title=title,
            source_type=source_type,
        ))
    return documents
