"""Ingestion-time safety screening (GATE 21).

Two independent deterministic scans over chunk text (treated as DATA):

1. Suspicious-content classification — narrow, instruction-shaped
   patterns grouped by reason-code family.  A match routes the chunk to
   ``review_quarantined`` (excluded from the active serving set, counted,
   reported) — never silently deleted, never executed, never allowed to
   influence prompts, tools, URLs, code, files, databases, or credentials.
   Deliberately tighter than substring matching: bare ``system:`` is NOT a
   pattern (it occurs inside ``ecosystem:``); only multi-word instruction
   shapes match, so legitimate prose such as "nervous system",
   "instruction manual", or "system of equations" stays clean.
2. PII/secret scanning — email, JWT, and assignment-shaped secret
   patterns.  ANY hit is a hard failure signal for the artifact
   (the pipeline stops; findings are never redacted-and-continued).

Pattern lists are fixed and reviewable — not a general content filter, and
never an LLM trust decision.
"""

from __future__ import annotations

import re

#: (reason_code, case-insensitive substring) — all multi-word shapes.
SUSPICIOUS_PATTERNS: tuple[tuple[str, str], ...] = (
    ("prompt_injection", "ignore previous instructions"),
    ("prompt_injection", "ignore all instructions"),
    ("prompt_injection", "ignore your instructions"),
    ("prompt_injection", "disregard previous instructions"),
    ("prompt_injection", "disregard all instructions"),
    ("instruction_hijack", "override your instructions"),
    ("instruction_hijack", "new instructions:"),
    ("instruction_hijack", "forget everything above"),
    ("impersonation", "system message"),
    ("impersonation", "system prompt"),
    ("impersonation", "system instruction"),
    ("impersonation", "developer instruction"),
    ("impersonation", "you are now a"),
    ("impersonation", "act as if you are"),
    ("credential_request", "send credentials"),
    ("credential_request", "reveal secrets"),
    ("credential_request", "show api key"),
    ("credential_request", "enter your password"),
    ("credential_request", "type your password"),
    ("exfiltration", "send it to http"),
    ("exfiltration", "post it to http"),
    ("exfiltration", "upload to http"),
    ("tool_invocation", "run the following command"),
    ("tool_invocation", "execute the following code"),
    ("tool_invocation", "open this url"),
    ("tool_invocation", "fetch this url"),
    ("tool_invocation", "call the function"),
    ("code_execution", "os.system("),
    ("code_execution", "import subprocess"),
    ("code_execution", "subprocess."),
    ("code_execution", "eval(malicious"),
    ("code_execution", "<script>"),
)

#: PII/secret content patterns (regex, any hit is critical).
EMAIL_RE = re.compile(
    r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}")
JWT_RE = re.compile(r"eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+")
SECRET_ASSIGN_RE = re.compile(
    r"(?i)\b(api[_-]?key|password|passwd|secret|db_password|jwt_secret)"
    r"\s*[:=]\s*['\"]?[^'\"\s]{4,}")
BEARER_RE = re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._~-]+")


def screen_text(text: str) -> dict:
    """Classify chunk text: clean or quarantined with reason codes."""
    lowered = text.lower()
    codes: list[str] = []
    for code, pattern in SUSPICIOUS_PATTERNS:
        if pattern in lowered and code not in codes:
            codes.append(code)
    if codes:
        return {"status": "review_quarantined", "reason_codes": codes}
    return {"status": "clean", "reason_codes": []}


def scan_secrets(text: str) -> list[str]:
    """Return hit descriptions for PII/secret patterns (empty = clean)."""
    hits: list[str] = []
    for name, pattern in (("email", EMAIL_RE), ("jwt", JWT_RE),
                          ("secret_assignment", SECRET_ASSIGN_RE),
                          ("bearer_token", BEARER_RE)):
        match = pattern.search(text)
        if match:
            hits.append(f"{name}:{match.group(0)[:32]}")
    return hits
