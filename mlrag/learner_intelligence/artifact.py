"""Versioned JSON-only learner-model artifact (Gate 24).

No pickle, no executable payloads: the artifact is a manifest of
fitted PARAMETERS (importances / coefficients, train rate, class
counts) plus full provenance.  Serving never unpickles anything, so
there is no code-execution surface; retraining from live data is cheap
(seconds) and is the sanctioned refresh path.

``load_for_serving`` refuses to return a servable model unless EVERY
gate passes:

* artifact parses and carries the exact required key set
* model id/version and feature/dataset versions match expectations
* dataset fingerprint matches the live dataset
* ``production_eligibility`` is explicitly true
* calibration status is not a blocking state

Any failure raises (never a silent degraded model): ``StaleModel`` for
fingerprint drift, ``CorruptModel`` for structural problems, and
``ModelNotEligible`` for an honestly-recorded NOT-READY verdict.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

from ..modeling import preprocessing as g19_preprocessing
from . import config24

ARTIFACT_VERSION = "lm1"

REQUIRED_KEYS = frozenset({
    "artifact_version",
    "model_id",
    "model_version",
    "model_family",
    "model_config",
    "feature_version",
    "dataset_version",
    "dataset_fingerprint",
    "data_version",
    "train_population",
    "preprocessing",
    "preprocessing_fitted",
    "parameters",
    "evaluation_summary",
    "calibration_status",
    "production_eligibility",
    "promotion_blockers",
    "library_versions",
    "python_version",
    "created_at_utc",
    "artifact_fingerprint",
})


class ModelArtifactError(Exception):
    """Base class for artifact integrity failures."""


class StaleModel(ModelArtifactError):
    """Dataset fingerprint drifted: rebuild, never serve stale weights."""


class CorruptModel(ModelArtifactError):
    """Structural/schema failure: rebuild, never guess."""


class ModelNotEligible(ModelArtifactError):
    """Honestly-recorded NOT-READY verdict: deterministic fallback."""


def _canonical(value: object) -> str:
    return json.dumps(value, sort_keys=True, ensure_ascii=False,
                      separators=(",", ":"))


def fingerprint_record(record: dict) -> str:
    """Fingerprint over everything except the fingerprint field itself."""
    payload = {k: v for k, v in record.items()
               if k != "artifact_fingerprint"}
    return hashlib.sha256(_canonical(payload).encode("utf-8")).hexdigest()


def build_artifact(*, model_id: str, model_version: str, model_family: str,
                   model_config: dict, dataset_fingerprint: str,
                   data_version: str,                    train_population: dict,
                   preprocessing_report: dict,
                   preprocessing_fitted: dict, parameters: dict,
                   evaluation_summary: dict, calibration_status: str,
                   production_eligibility: bool,
                   promotion_blockers: list[str],
                   library_versions: dict, python_version: str) -> dict:
    """Assemble + fingerprint the artifact record (no I/O)."""
    record = {
        "artifact_version": ARTIFACT_VERSION,
        "model_id": model_id,
        "model_version": model_version,
        "model_family": model_family,
        "model_config": model_config,
        "feature_version": config24.FEATURE_VERSION,
        "dataset_version": config24.DATASET_VERSION,
        "dataset_fingerprint": dataset_fingerprint,
        "data_version": data_version,
        "train_population": train_population,
        "preprocessing": preprocessing_report,
        "preprocessing_fitted": preprocessing_fitted,
        "parameters": parameters,
        "evaluation_summary": evaluation_summary,
        "calibration_status": calibration_status,
        "production_eligibility": bool(production_eligibility),
        "promotion_blockers": list(promotion_blockers),
        "library_versions": library_versions,
        "python_version": python_version,
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
    }
    record["artifact_fingerprint"] = fingerprint_record(record)
    missing = REQUIRED_KEYS - set(record.keys())
    if missing:
        raise CorruptModel(f"artifact missing keys: {sorted(missing)}")
    return record


def write_artifact(record: dict, path: Path) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(record, indent=2, sort_keys=True) + "\n",
                    encoding="utf-8")
    return path


def read_artifact(path: Path) -> dict:
    try:
        record = json.loads(Path(path).read_text(encoding="utf-8"))
    except Exception as exc:
        raise CorruptModel(f"artifact unreadable: {exc}") from exc
    if not isinstance(record, dict):
        raise CorruptModel("artifact root must be an object")
    missing = REQUIRED_KEYS - set(record.keys())
    if missing:
        raise CorruptModel(f"artifact missing keys: {sorted(missing)}")
    if record.get("artifact_version") != ARTIFACT_VERSION:
        raise CorruptModel(
            f"unsupported artifact_version {record.get('artifact_version')!r}")
    if fingerprint_record(record) != record.get("artifact_fingerprint"):
        raise CorruptModel("artifact fingerprint mismatch (tampered?)")
    return record


def load_for_serving(path: Path, *, expected_model_id: str,
                     expected_model_version: str,
                     expected_feature_version: str,
                     expected_dataset_fingerprint: str) -> dict:
    """Strict serving gate.  Returns the record or raises — never partial."""
    record = read_artifact(path)
    if record["model_id"] != expected_model_id:
        raise CorruptModel("model id mismatch")
    if record["model_version"] != expected_model_version:
        raise CorruptModel("model version mismatch")
    if record["feature_version"] != expected_feature_version:
        raise CorruptModel(
            f"feature version mismatch (artifact={record['feature_version']}, "
            f"expected={expected_feature_version}): refusing stale model")
    if record["dataset_fingerprint"] != expected_dataset_fingerprint:
        raise StaleModel(
            "dataset fingerprint drifted: rebuild required, "
            "stale parameters never served")
    if record["production_eligibility"] is not True:
        raise ModelNotEligible(
            "model recorded as not production-eligible "
            f"(blockers: {record['promotion_blockers']}); "
            "deterministic fallback required")
    if str(record.get("calibration_status", "")).startswith("BLOCKED"):
        raise ModelNotEligible("calibration blocking state")
    return record


def preprocessing_fingerprint_note(preprocessor) -> dict:
    """Record the frozen preprocessing actually fitted (reviewable)."""
    return g19_preprocessing.imputation_report(preprocessor)
