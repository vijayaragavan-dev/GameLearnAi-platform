"""Read-only MySQL access for the offline ML experiment (GATE 4).

Rules enforced here, not by convention:
  * credentials come ONLY from MLRAG_DB_* environment variables;
  * the connected account MUST be the dedicated read-only account;
  * every statement is validated SELECT/SHOW/DESCRIBE/EXPLAIN-only,
    single-statement, with dangerous keywords rejected;
  * nothing is ever written, committed, or logged (no credential logging).
"""

from __future__ import annotations

import os
import re
from typing import Any, Mapping, Sequence

import pymysql
import pymysql.cursors

from mlrag.contracts.common import ContractViolation

READ_ONLY_USER = "gamelearn_ro"

_READ_PREFIXES = ("SELECT", "SHOW", "DESCRIBE", "DESC", "EXPLAIN")
_FORBIDDEN_KEYWORDS = (
    "INSERT",
    "UPDATE",
    "DELETE",
    "ALTER",
    "DROP",
    "TRUNCATE",
    "CREATE",
    "REPLACE",
    "MERGE",
    "CALL ",
    "LOAD DATA",
    "GRANT",
    "REVOKE",
    "INTO OUTFILE",
    "INTO DUMPFILE",
    "HANDLER",
    "LOCK TABLES",
)


def _require_env(name: str) -> str:
    value = os.environ.get(name)
    if value is None or not value.strip():
        raise ContractViolation(f"missing required environment variable: {name}")
    return value.strip()


def _parse_url(url: str) -> tuple[str, int, str]:
    """Parse mysql://host:port/database (jdbc:mysql:// prefix tolerated)."""
    cleaned = url.strip()
    for prefix in ("jdbc:mysql://", "mysql://"):
        if cleaned.startswith(prefix):
            cleaned = cleaned[len(prefix):]
            break
    hostport, _, database = cleaned.partition("/")
    if not database:
        raise ContractViolation("MLRAG_DB_URL must include a database name")
    host, _, port_raw = hostport.partition(":")
    port = int(port_raw) if port_raw else 3306
    return host or "127.0.0.1", port, database


def connect() -> Any:
    """Open a read-only connection; refuse anything but gamelearn_ro."""
    url = os.environ.get("MLRAG_DB_URL", "").strip()
    if url:
        host, port, database = _parse_url(url)
    else:
        host = os.environ.get("MLRAG_DB_HOST", "127.0.0.1").strip()
        port = int(os.environ.get("MLRAG_DB_PORT", "3306").strip())
        database = _require_env("MLRAG_DB_DATABASE")
    username = _require_env("MLRAG_DB_USERNAME")
    password = _require_env("MLRAG_DB_PASSWORD")
    conn = pymysql.connect(
        host=host,
        port=port,
        user=username,
        password=password,
        database=database,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        read_timeout=15,
        write_timeout=15,
        autocommit=True,
    )
    try:
        with conn.cursor() as cur:
            cur.execute("SELECT CURRENT_USER() AS who")
            who = cur.fetchone()["who"]
        if READ_ONLY_USER not in who:
            conn.close()
            raise ContractViolation(
                "refusing connection: expected read-only account "
                f"'{READ_ONLY_USER}'"
            )
        return conn
    except Exception:
        conn.close()
        raise


def run_select(
    conn: Any, sql: str, params: Sequence[Any] | Mapping[str, Any] | None = None
) -> list[dict]:
    """Execute one validated read-only statement; return all rows."""
    statement = sql.strip().rstrip(";").strip()
    upper = statement.upper()
    if not upper.startswith(_READ_PREFIXES):
        raise ContractViolation("only read-only statements are allowed")
    if ";" in statement:
        raise ContractViolation("multi-statements are forbidden")
    for keyword in _FORBIDDEN_KEYWORDS:
        # Word boundaries: column names like created_at must not match
        # keywords like CREATE.
        if re.search(r"\b" + keyword.strip() + r"\b", upper):
            raise ContractViolation(
                f"forbidden keyword in read-only query: {keyword.strip()}"
            )
    with conn.cursor() as cur:
        cur.execute(statement, params or ())
        return list(cur.fetchall())
