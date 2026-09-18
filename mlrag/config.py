"""Configuration boundary for the ML/RAG sidecar (GATE 1).

Rules: no hardcoded secrets, keys, passwords, or production URLs anywhere
in this package.  All runtime values come from the environment with safe
defaults; the sidecar is DISABLED by default and must be enabled explicitly
per surface later.  Secrets must never be logged.
"""

from __future__ import annotations

import os
from dataclasses import dataclass

from .contracts.common import ContractViolation


@dataclass(frozen=True)
class SidecarConfig:
    """Static sidecar configuration.  No networking is implemented in GATE 1."""

    enabled: bool = False
    predict_timeout_ms: int = 800
    retrieve_timeout_ms: int = 1200
    max_top_k: int = 10
    model_version_expected: str = ""
    log_level: str = "INFO"

    def __post_init__(self) -> None:
        if self.predict_timeout_ms <= 0 or self.retrieve_timeout_ms <= 0:
            raise ContractViolation("timeouts must be positive")
        if not 1 <= self.max_top_k <= 50:
            raise ContractViolation("max_top_k must be within 1..50")
        if self.log_level not in ("DEBUG", "INFO", "WARNING", "ERROR"):
            raise ContractViolation(f"unknown log_level: {self.log_level}")

    @classmethod
    def from_env(cls, prefix: str = "MLRAG_") -> "SidecarConfig":
        """Build config from environment.  No secret has a default value."""

        def _int(name: str, default: int) -> int:
            raw = os.environ.get(prefix + name)
            if raw is None or not raw.strip():
                return default
            try:
                return int(raw)
            except ValueError as exc:
                raise ContractViolation(
                    f"{prefix + name} must be an integer"
                ) from exc

        def _str(name: str, default: str = "") -> str:
            return os.environ.get(prefix + name, default)

        enabled_raw = _str("ENABLED", "false").strip().lower()
        return cls(
            enabled=enabled_raw in ("1", "true", "yes"),
            predict_timeout_ms=_int("PREDICT_TIMEOUT_MS", 800),
            retrieve_timeout_ms=_int("RETRIEVE_TIMEOUT_MS", 1200),
            max_top_k=_int("MAX_TOP_K", 10),
            model_version_expected=_str("MODEL_VERSION_EXPECTED"),
            log_level=_str("LOG_LEVEL", "INFO").upper(),
        )
