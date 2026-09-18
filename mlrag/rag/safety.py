"""Retrieved-text-as-DATA boundary (GATE 6, PHASE 8).

Corpus text is educational content, never instructions.  This module keeps
it that way: wrap retrieved spans in explicit DATA delimiters with control
characters stripped, and quarantine spans that attempt instruction
override (fixed, reviewable pattern list — not a general content filter).
Scope enforcement itself lives in retrieval code, never in prompts.
"""

from __future__ import annotations

import re

from .errors import InstructionOverrideBlocked

DATA_BEGIN = "<<<RETRIEVED-DATA-BEGIN>>>"
DATA_END = "<<<RETRIEVED-DATA-END>>>"

_CONTROL_CHARS = re.compile(r"[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]")

#: Imperative override attempts (case-insensitive substring match).
#: Narrow by design: instruction-shaped demands, not educational prose.
_OVERRIDE_PATTERNS = (
    "ignore previous instructions",
    "ignore all instructions",
    "ignore your instructions",
    "disregard previous instructions",
    "disregard all instructions",
    "override your instructions",
    "new instructions:",
    "system:",
    "reveal your prompt",
    "reveal system prompt",
    "show your instructions",
    "bypass scope",
    "override scope",
    "change application rules",
    "reveal secrets",
    "show api key",
)


def wrap_as_data(text: str) -> str:
    """Delimit retrieved text as data; strip control characters."""
    cleaned = _CONTROL_CHARS.sub("", text)
    return f"{DATA_BEGIN}\n{cleaned}\n{DATA_END}"


def check_no_instruction_override(text: str) -> str:
    """Quarantine spans shaped as instruction-override attempts."""
    lowered = text.lower()
    for pattern in _OVERRIDE_PATTERNS:
        if pattern in lowered:
            raise InstructionOverrideBlocked(
                f"retrieved text blocked as instruction override: {pattern!r}")
    return text


def prepare_context_span(text: str) -> str:
    """Full boundary: quarantine first, then delimit as data."""
    return wrap_as_data(check_no_instruction_override(text))
