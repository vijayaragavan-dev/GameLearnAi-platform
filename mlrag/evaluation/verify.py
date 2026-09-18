"""Gate 19 artifact verification (GATE 20 §1).

Checks, in order: experiment + model artifacts exist and parse; model /
feature / dataset versions equal the frozen Gate 19 values; the live
dataset fingerprint matches the fingerprint recorded in the Gate 19
artifacts (any silent regeneration is a hard failure); the recorded split
assignment matches the live Gate 18 split; the challenger configuration is
byte-identical to frozen (no tuning drift); serialized artifacts are
safety-scanned.  Any failure raises :class:`ContractViolation` — evaluation
never proceeds on unverified inputs.
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from ..contracts.common import ContractViolation
from ..dataset.contract import scan_prohibited_content
from ..modeling import config as challenger_config

#: Frozen Gate 19 identities (duplicated here as verification constants —
#: any drift in `mlrag.modeling.config` is itself a failure, caught below).
MODEL_ID = "logreg-pcorrect-g19"
MODEL_VERSION = "0.1.0-gate19exp"
FEATURE_VERSION = "f1"
DATASET_VERSION = "d1"
FROZEN_SOLVER = ("lbfgs", 1.0, 1000, 42)

ARTIFACT_DIR = Path(__file__).resolve().parent.parent / "artifacts"
EXPERIMENT_ARTIFACT = ARTIFACT_DIR / "gate19_experiment.json"
MODEL_ARTIFACT = ARTIFACT_DIR / "gate19_model.json"


def _load(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise ContractViolation(
            f"cannot load Gate 19 artifact {path.name}: {exc}") from exc


def verify_config_frozen() -> dict[str, Any]:
    """Assert the Gate 19 challenger configuration is untouched."""
    observed = (
        challenger_config.MODEL_ID,
        challenger_config.MODEL_VERSION,
        challenger_config.FEATURE_VERSION,
        challenger_config.DATASET_VERSION,
        challenger_config.SOLVER,
        challenger_config.C_VALUE,
        challenger_config.MAX_ITER,
        challenger_config.RANDOM_STATE,
        len(challenger_config.MATRIX_COLUMNS),
    )
    expected = (MODEL_ID, MODEL_VERSION, FEATURE_VERSION, DATASET_VERSION,
                FROZEN_SOLVER[0], FROZEN_SOLVER[1], FROZEN_SOLVER[2],
                FROZEN_SOLVER[3], 31)
    if observed != expected:
        raise ContractViolation(
            f"Gate 19 challenger configuration drifted: {observed!r}")
    tuning_imports = ("GridSearchCV", "RandomizedSearchCV",
                      "BayesSearchCV", "train_test_split", "import random",
                      "import optuna", "import hyperopt")
    import inspect
    import mlrag.modeling.challenger as challenger_module
    import mlrag.modeling.experiment as experiment_module
    for module in (challenger_module, experiment_module):
        source = inspect.getsource(module)
        for banned in tuning_imports:
            if banned in source:
                raise ContractViolation(
                    f"tuning construct in {module.__name__}: {banned}")
    return {"config_frozen": True, "model_id": MODEL_ID,
            "model_version": MODEL_VERSION}


def verify_artifacts(live_fingerprint: str,
                     live_assignment: dict[str, str]) -> dict[str, Any]:
    """Verify recorded Gate 19 artifacts against live Gate 18 outputs."""
    experiment = _load(EXPERIMENT_ARTIFACT)
    model = _load(MODEL_ARTIFACT)
    for key, want in (("model_id", MODEL_ID),
                      ("model_version", MODEL_VERSION),
                      ("feature_version", FEATURE_VERSION),
                      ("dataset_version", DATASET_VERSION)):
        for artifact, name in ((experiment, "experiment"),
                               (model, "model")):
            if artifact.get(key) != want:
                raise ContractViolation(
                    f"Gate 19 {name} artifact {key}={artifact.get(key)!r} "
                    f"!= frozen {want!r}")
    recorded_fp = experiment.get("data_fingerprint")
    if recorded_fp != live_fingerprint:
        raise ContractViolation(
            f"dataset fingerprint drift: live {live_fingerprint!r} != "
            f"Gate 19 recorded {recorded_fp!r} (no silent regeneration)")
    if model.get("data_fingerprint") != live_fingerprint:
        raise ContractViolation("model artifact fingerprint mismatch")
    recorded_split = {
        r["row_id"]: r["split"]
        for r in experiment["lolo_protocol"].get("predictions", [])
    } or {
        r["row_id"]: r["split"]
        for r in experiment["split_protocol"].get("predictions", [])
    }
    mismatched = sorted(
        rid for rid, split in live_assignment.items()
        if rid in recorded_split and recorded_split[rid] != split)
    if mismatched:
        raise ContractViolation(
            f"split assignment drift on {len(mismatched)} rows")
    safety = {}
    for path in (EXPERIMENT_ARTIFACT, MODEL_ARTIFACT):
        hits = scan_prohibited_content(
            path.read_text(encoding="utf-8"))
        safety[path.name] = {"hits": hits, "safety_pass": not hits}
        if hits:
            raise ContractViolation(
                f"prohibited content in {path.name}: {hits}")
    return {
        "artifacts_present": True,
        "experiment_id": experiment.get("experiment_id"),
        "fingerprint_match": True,
        "split_match_rows": len(recorded_split),
        "split_mismatches": [],
        "safety": safety,
    }
