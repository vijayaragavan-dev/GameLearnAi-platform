"""Deterministic parser for the repo's Flyway seed SQL subset (GATE 7).

Handles exactly the two statement shapes the curriculum seeds use:
  * ``INSERT INTO <table> (<cols>) SELECT <values> FROM DUAL
    WHERE NOT EXISTS ... ;`` (one row per statement, V24/V27/V28 style;
    column lists may wrap across lines);
  * ``INSERT INTO <table> (<cols>) VALUES (<row>), (<row>), ... ;``
    (V11/V12/V14 style; string literals may span lines).

Literals: single-quoted strings with '' escapes, TRUE/FALSE,
CURRENT_TIMESTAMP (mapped to None = seed-time marker), NULL, integers,
decimals.  Anything else raises — the parser is strict on purpose so
format drift fails loudly instead of silently corrupting the corpus.
"""

from __future__ import annotations

import re

_HEADER = re.compile(
    r"INSERT\s+INTO\s+(\w+)\s*\(([^)]*)\)", re.IGNORECASE)
_MODE = re.compile(r"\s*(SELECT|VALUES)\b", re.IGNORECASE)
_FROM_DUAL = re.compile(r"FROM\s+DUAL\b", re.IGNORECASE)


def _mask_strings(text: str) -> str:
    """Replace string-literal contents with blanks (offsets preserved)."""
    chars = list(text)
    in_string = False
    i = 0
    while i < len(chars):
        char = chars[i]
        if in_string:
            if char == "'":
                if i + 1 < len(chars) and chars[i + 1] == "'":
                    chars[i + 1] = " "
                else:
                    in_string = False
            else:
                chars[i] = " "
        elif char == "'":
            in_string = True
        i += 1
    return "".join(chars)

APPROVED_TABLES = frozenset(
    {"subjects", "units", "topics", "lessons", "questions"})


def _strip_comments(text: str) -> str:
    out: list[str] = []
    in_string = False
    i = 0
    while i < len(text):
        char = text[i]
        if in_string:
            out.append(char)
            if char == "'":
                if i + 1 < len(text) and text[i + 1] == "'":
                    out.append("'")
                    i += 1
                else:
                    in_string = False
        elif char == "'":
            in_string = True
            out.append(char)
        elif char == "-" and text[i:i + 2] == "--":
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        else:
            out.append(char)
        i += 1
    return "".join(out)


def _split_top_level(body: str) -> list[str]:
    parts: list[str] = []
    depth = 0
    in_string = False
    current: list[str] = []
    i = 0
    while i < len(body):
        char = body[i]
        if in_string:
            current.append(char)
            if char == "'":
                if i + 1 < len(body) and body[i + 1] == "'":
                    current.append("'")
                    i += 1
                else:
                    in_string = False
        elif char == "'":
            in_string = True
            current.append(char)
        elif char == "(":
            depth += 1
            current.append(char)
        elif char == ")":
            depth -= 1
            current.append(char)
        elif char == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(char)
        i += 1
    tail = "".join(current).strip()
    if tail:
        parts.append(tail)
    return parts


def _literal(token: str):
    token = token.strip()
    if len(token) >= 2 and token.startswith("'") and token.endswith("'"):
        return token[1:-1].replace("''", "'")
    upper = token.upper()
    if upper == "TRUE":
        return True
    if upper == "FALSE":
        return False
    if upper in ("NULL", "CURRENT_TIMESTAMP"):
        return None
    try:
        return int(token)
    except ValueError:
        pass
    try:
        return float(token)
    except ValueError:
        pass
    raise ValueError(f"unsupported SQL literal: {token!r}")


def _parse_tuple(text: str) -> list:
    text = text.strip()
    if not (text.startswith("(") and text.endswith(")")):
        raise ValueError(f"not a row tuple: {text[:60]!r}")
    return [_literal(part) for part in _split_top_level(text[1:-1])]


def parse_seed_sql(text: str) -> dict[str, list[dict]]:
    """Parse seed SQL into {table: [row dicts]} for approved tables.

    String-aware scanning throughout: semicolons or keywords inside
    quoted literals (lesson prose, explanations) never terminate or
    confuse statement parsing.  SQL comments are stripped first by a
    string-aware pass; all subsequent offsets refer to the stripped text.
    """
    source = _strip_comments(text)
    masked = _mask_strings(source)
    tables: dict[str, list[dict]] = {}
    for header in _HEADER.finditer(masked):
        table = header.group(1)
        raw_cols = header.group(2)
        if table not in APPROVED_TABLES:
            continue
        mode = _MODE.match(masked, header.end())
        if mode is None:
            raise ValueError(f"unsupported INSERT shape for {table}")
        body_start = mode.end()
        terminator = masked.find(";", body_start)
        if terminator == -1:
            raise ValueError(f"unterminated statement for {table}")
        columns = [c.strip().strip('"').strip("`").lower()
                   for c in raw_cols.split(",")]
        if mode.group(1).upper() == "SELECT":
            dual = _FROM_DUAL.search(masked, body_start, terminator)
            if dual is None:
                raise ValueError(f"SELECT without FROM DUAL in {table}")
            rows = [_parse_tuple(
                f"({source[body_start:dual.start()].strip()})")]
        else:
            region = source[body_start:terminator]
            rows = [_parse_tuple(part) for part in
                    _split_top_level(region) if part.strip()]
        for values in rows:
            if len(values) != len(columns):
                raise ValueError(
                    f"column/value arity mismatch in {table}: "
                    f"{len(columns)} vs {len(values)}")
            tables.setdefault(table, []).append(dict(zip(columns, values)))
    return tables


def parse_seed_files(paths: list[str]) -> dict[str, list[dict]]:
    """Parse several seed files; concatenate per-table rows in order."""
    merged: dict[str, list[dict]] = {}
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            parsed = parse_seed_sql(handle.read())
        for table, rows in parsed.items():
            merged.setdefault(table, []).extend(rows)
    return merged
