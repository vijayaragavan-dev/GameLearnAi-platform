"""Learner-intelligence layer (Gate 24): honest ML signal, dormant serving.

Boundary (non-negotiable):

* The deterministic AdaptiveEngine remains the SOLE authority for
  mastery / difficulty / progression / recommendations / XP / scoring.
* This package produces a BOUNDED probability signal with explicit
  validity metadata, plus a serving contract that FALLS BACK to
  deterministic behavior unless every safety gate passes.
* Current data (≈60 rows) cannot support promotion; the artifact
  records that verdict and the serving contract enforces it.  That is
  the correct engineering outcome, not a failure.

Contents:

* ``config24`` — frozen E configuration, versions, cold-start bands,
  numerical tolerance.
* ``challenger_rf`` — ONE constrained nonlinear challenger (E) on the
  frozen f1/31-column matrix.  No tuning grid exists by design.
* ``runner`` — the two leakage-safe protocols (Gate 18 split + LOLO)
  for an arbitrary candidate, reusing modeling primitives.
* ``calibration24`` — ECE/reliability assessment + principled
  recalibration decline rule.
* ``artifact`` — versioned JSON-only model record (no pickle) with
  strict load verification.
* ``serving`` — prediction-service contract: Prediction or explicit
  Fallback.  Never serves an ineligible model.
* ``promotion24`` — promotion evidence assembly on frozen bars.
* ``snapshot`` — live read-only runner (experiment + artifact).
"""
