"""Deterministic content normalization + SHA-256 hashing (GATE 21).

Policy (documented, meaning-preserving only):

* Unicode NFC composition (canonical equivalence — ``NFC``, never ``NFKC``,
  which can silently merge distinct characters);
* CRLF/CR line endings -> LF;
* trailing whitespace stripped per line;
* runs of 3+ blank lines collapsed to exactly 2 (paragraph structure kept);
* leading/trailing overall whitespace stripped.

Explicitly NOT done: paraphrasing, LLM cleaning, fact correction,
concept merging, text invention.  The original source hash is always kept
alongside the normalized hash so the two remain distinguishable.
"""

from __future__ import annotations

import hashlib
import json
import re
import unicodedata

_BLANK_RUN = re.compile(r"\n{4,}")


def sha256_hex(payload: str) -> str:
    """Deterministic SHA-256 hex digest (sole integrity hash)."""
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def normalize_text(text: str) -> str:
    """Apply the documented normalization policy deterministically."""
    composed = unicodedata.normalize("NFC", text)
    unified = composed.replace("\r\n", "\n").replace("\r", "\n")
    lines = [line.rstrip() for line in unified.split("\n")]
    collapsed = _BLANK_RUN.sub("\n\n\n", "\n".join(lines))
    return collapsed.strip()


def canonical_record(fields: dict) -> str:
    """Canonical JSON for hashing source records (sorted keys, str() values)."""
    return json.dumps({k: str(v) for k, v in sorted(fields.items())},
                      sort_keys=True, ensure_ascii=False)


def source_hash(source_table: str, source_fields: dict) -> str:
    """Hash of the original source representation (pre-normalization)."""
    return sha256_hex(f"{source_table}\n{canonical_record(source_fields)}")
