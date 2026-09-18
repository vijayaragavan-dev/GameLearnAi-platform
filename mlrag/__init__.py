"""GameLearnAI ML/RAG sidecar — architecture skeleton (GATE 1).

Responsibility (future): feature preparation, model training/evaluation,
inference, retrieval, embeddings, ingestion.  This package currently defines
typed contracts/ports ONLY.  No model, no retrieval backend, no networking.

Non-negotiable rule: Spring Boot remains the authoritative application layer
(auth, quiz evaluation, mastery, AdaptiveEngine, persistence).  ML = signal
provider.  See README.md.
"""

__version__ = "0.1.0-gate1"
