"""Safe shadow-mode offline replay (GATE 9). Advisory only; the
deterministic AdaptiveEngine remains authoritative; nothing here mutates
learner state, calls services, or touches production."""

from . import contracts, evaluator, replay

__all__ = ["contracts", "evaluator", "replay"]
