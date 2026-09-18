"""Gate 22 tests: model configuration, pinning, determinism, artifacts.

Categories covered: model configuration (1), model pinning (2), embedding
determinism (3), embedding dimensions (4), corpus fingerprint binding (5),
stale artifact detection (6), index persistence/reload (7), artifact
corruption (23), reproducibility (24).  Retrieval behavior lives in
test_gate22_hf_retrieval.py; adversarial/security in
test_gate22_hf_security_eval.py.

All fixture IDs are labeled; the only real corpus content touched is the
committed Gate 21 artifact (read-only).  No database, no network beyond
the initial pinned-model download, no LLM calls.
"""

from __future__ import annotations

import json
import unittest
from pathlib import Path

from mlrag.contracts.common import ContractViolation
from mlrag.embeddings import model_registry
from mlrag.embeddings.hf_embedder import HFEmbedder, prepare_query_text
from mlrag.embeddings.pipeline import (
    CorruptEmbeddingArtifact,
    StaleEmbeddingArtifact,
    config_fingerprint,
    embedding_fingerprint,
    library_versions,
    load_artifact,
    load_gate21_chunks,
    verify_binding_against_live_corpus,
)
from mlrag.rag.errors import EmbeddingFailure

from . import gate22_helpers as H


class ModelRegistryTest(unittest.TestCase):
    """Categories 1-2: configuration + pinning recorded before use."""

    def test_exactly_one_selected_candidate(self):
        selected = [c for c in model_registry.CANDIDATES
                    if c.get("selected") is True]
        self.assertEqual(len(selected), 1)

    def test_selected_model_identity_pinned(self):
        self.assertEqual(model_registry.SELECTED_MODEL_ID,
                         "sentence-transformers/all-MiniLM-L6-v2")
        rev = model_registry.SELECTED_MODEL_REVISION
        self.assertRegex(rev, r"^[0-9a-f]{40}$")

    def test_every_candidate_fully_documented(self):
        required = {"model_id", "revision", "embedding_dimension",
                    "approx_params", "license", "intended_task",
                    "query_document_encoding", "cpu_feasible",
                    "expected_memory", "limitations", "selection_reason"}
        for candidate in model_registry.CANDIDATES:
            self.assertTrue(required <= set(candidate.keys()),
                            candidate.get("model_id"))
            self.assertRegex(str(candidate["revision"]), r"^[0-9a-f]{40}$")
            self.assertIn(str(candidate["license"]), ("Apache-2.0", "MIT"))

    def test_registry_dimension_matches_selected(self):
        self.assertEqual(model_registry.EMBEDDING_DIMENSION, 384)
        selected = model_registry.selected_candidate()
        self.assertEqual(selected["embedding_dimension"], 384)

    def test_expected_corpus_constants_match_live(self):
        chunks, fingerprint = load_gate21_chunks(H.CORPUS_PATH)
        self.assertEqual(fingerprint,
                         model_registry.EXPECTED_GATE21_FINGERPRINT)
        self.assertEqual(len(chunks),
                         model_registry.EXPECTED_GATE21_CHUNKS)

    def test_no_latest_semantics(self):
        self.assertNotIn("latest", model_registry.SELECTED_MODEL_REVISION)
        self.assertNotIn("main", model_registry.SELECTED_MODEL_REVISION)


class QueryPreparationTest(unittest.TestCase):
    """Query safety at the embedding boundary (untrusted input)."""

    def test_empty_query_rejected(self):
        with self.assertRaises(ContractViolation):
            prepare_query_text("   ")

    def test_non_string_rejected(self):
        with self.assertRaises(ContractViolation):
            prepare_query_text(None)  # type: ignore[arg-type]

    def test_oversized_query_truncated_deterministically(self):
        long_query = "x" * (model_registry.MAX_QUERY_CHARS + 500)
        prepared = prepare_query_text(long_query)
        self.assertEqual(len(prepared), model_registry.MAX_QUERY_CHARS)
        self.assertEqual(prepared, long_query[:model_registry.MAX_QUERY_CHARS])

    def test_boundary_length_kept_verbatim(self):
        exact = "y" * model_registry.MAX_QUERY_CHARS
        self.assertEqual(prepare_query_text(exact), exact)


class EmbedderContractTest(unittest.TestCase):
    """Categories 2-4: pinning enforced, dimensions verified, no fakes."""

    def test_unpinned_revision_rejected(self):
        with self.assertRaises(ContractViolation):
            HFEmbedder(revision="")

    def test_non_cpu_device_rejected(self):
        with self.assertRaises(ContractViolation):
            HFEmbedder(device="cuda")

    def test_empty_embed_inputs_rejected_without_model(self):
        with self.assertRaises(ContractViolation):
            HFEmbedder().embed([])

    def test_blank_embed_input_rejected(self):
        with self.assertRaises(ContractViolation):
            HFEmbedder().embed(["  "])

    def test_version_string_pins_model_and_config(self):
        version = HFEmbedder().version
        self.assertIn(model_registry.SELECTED_MODEL_ID, version)
        self.assertIn(model_registry.SELECTED_MODEL_REVISION[:12], version)
        self.assertIn("dim384", version)

    def test_dimension_is_384(self):
        self.assertEqual(H.get_embedder().dimension, 384)

    def test_deterministic_embeddings_within_tolerance(self):
        import numpy as np
        embedder = H.get_embedder()
        texts = ["Photosynthesis converts light into chemical energy.",
                 "Routers forward packets by longest-prefix match."]
        first = np.asarray(embedder.embed(texts))
        second = np.asarray(embedder.embed(texts))
        self.assertEqual(first.shape, (2, 384))
        self.assertLessEqual(float(np.abs(first - second).max()),
                             model_registry.NUMERICAL_TOLERANCE)

    def test_embeddings_are_l2_normalized(self):
        import numpy as np
        vectors = np.asarray(H.get_embedder().embed(["sample text here"]))
        self.assertAlmostEqual(float(np.linalg.norm(vectors[0])), 1.0,
                               places=5)

    def test_unknown_model_raises_explicitly_never_fakes(self):
        bad = HFEmbedder(model_id="no-such-org-xyz/no-such-model-xyz",
                         revision="0" * 40)
        with self.assertRaises(EmbeddingFailure):
            bad.embed(["hello world"])


class ArtifactIntegrityTest(unittest.TestCase):
    """Categories 5-7, 23-24: binding, staleness, persistence, corruption."""

    def test_live_corpus_loads_413_sorted_unique(self):
        chunks, fingerprint = load_gate21_chunks(H.CORPUS_PATH)
        self.assertEqual(len(chunks), 413)
        self.assertEqual(fingerprint,
                         "451ddef72317c230f7f59a873e7ec8595068ae5c0277dca6bac1b900a946f2b9")
        ids = [c["chunk_id"] for c in chunks]
        self.assertEqual(ids, sorted(ids))
        self.assertEqual(len(set(ids)), len(ids))

    def test_manifest_pins_model_corpus_and_config(self):
        manifest = json.loads(H.MANIFEST_PATH.read_text(encoding="utf-8"))
        self.assertEqual(manifest["model_id"],
                         model_registry.SELECTED_MODEL_ID)
        self.assertEqual(manifest["model_revision"],
                         model_registry.SELECTED_MODEL_REVISION)
        self.assertEqual(manifest["embedding_dimension"], 384)
        self.assertEqual(manifest["similarity_metric"], "cosine")
        self.assertEqual(manifest["index_format"], model_registry.INDEX_FORMAT)
        self.assertEqual(manifest["corpus_fingerprint"],
                         model_registry.EXPECTED_GATE21_FINGERPRINT)
        self.assertEqual(manifest["corpus_size"], 413)
        for key in ("library_versions", "config_fingerprint",
                    "embedding_fingerprint", "chunk_ids_sha256",
                    "created_at_utc"):
            self.assertTrue(manifest.get(key), key)

    def test_binding_against_live_corpus(self):
        manifest = json.loads(H.MANIFEST_PATH.read_text(encoding="utf-8"))
        verdict = verify_binding_against_live_corpus(manifest, H.CORPUS_PATH)
        self.assertTrue(verdict["bound"])
        self.assertEqual(verdict["live_fp"], verdict["index_fp"])

    def test_config_fingerprint_reproducible_in_this_env(self):
        manifest = json.loads(H.MANIFEST_PATH.read_text(encoding="utf-8"))
        self.assertEqual(config_fingerprint(library_versions()),
                         manifest["config_fingerprint"])

    def test_reload_verifies_and_matches(self):
        matrix, chunk_ids, manifest = load_artifact(H.INDEX_PATH,
                                                    H.MANIFEST_PATH)
        self.assertEqual(matrix.shape, (413, 384))
        self.assertEqual(len(chunk_ids), 413)
        self.assertEqual(embedding_fingerprint(matrix),
                         manifest["embedding_fingerprint"])

    def test_stale_fingerprint_refused(self):
        with self.assertRaises(StaleEmbeddingArtifact):
            load_artifact(H.INDEX_PATH, H.MANIFEST_PATH,
                          expected_corpus_fingerprint="0" * 64)

    def test_live_fingerprint_accepted(self):
        matrix, _, _ = load_artifact(
            H.INDEX_PATH, H.MANIFEST_PATH,
            expected_corpus_fingerprint=(
                model_registry.EXPECTED_GATE21_FINGERPRINT))
        self.assertEqual(matrix.shape, (413, 384))

    def test_missing_files_refused(self):
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            missing = H.INDEX_PATH.parent / "definitely-missing.npz"
            _ = tmp  # silence unused warning (tmpdir auto-cleaned)
            with self.assertRaises(CorruptEmbeddingArtifact):
                load_artifact(missing, H.MANIFEST_PATH)

    def test_corrupted_bytes_refused(self):
        import shutil
        import tempfile
        with tempfile.TemporaryDirectory() as tmp:
            poisoned = Path(tmp) / "poisoned.npz"
            shutil.copy(H.INDEX_PATH, poisoned)
            with open(poisoned, "r+b") as handle:
                handle.seek(200)
                handle.write(b"\x00\xff\x00\xff")
            with self.assertRaises(CorruptEmbeddingArtifact):
                load_artifact(poisoned, H.MANIFEST_PATH)

    def test_wrong_model_manifest_refused(self):
        import tempfile
        manifest = json.loads(H.MANIFEST_PATH.read_text(encoding="utf-8"))
        manifest["model_id"] = "someone-else/other-model"
        with tempfile.TemporaryDirectory() as tmp:
            forged = Path(tmp) / "forged.json"
            forged.write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaises(CorruptEmbeddingArtifact):
                load_artifact(H.INDEX_PATH, forged)

    def test_reembedded_subset_matches_index_within_tolerance(self):
        import numpy as np
        chunks, _ = load_gate21_chunks(H.CORPUS_PATH)
        matrix, chunk_ids, _ = load_artifact(H.INDEX_PATH, H.MANIFEST_PATH)
        row_of = {doc_id: i for i, doc_id in enumerate(chunk_ids)}
        subset = chunks[:5]
        fresh = np.asarray(H.get_embedder().embed(
            [c["text"] for c in subset]), dtype=np.float32)
        stored = matrix[np.asarray([row_of[c["chunk_id"]] for c in subset])]
        self.assertLessEqual(float(np.abs(fresh - stored).max()),
                             model_registry.NUMERICAL_TOLERANCE)


if __name__ == "__main__":
    unittest.main()
