"""Build the Gate 22 deterministic retrieval eval dataset (one-shot script).

Reads the LIVE Gate 21 corpus artifact, stride-samples chunks per source
table, and derives extractive queries (title + lead sentence) whose single
relevant target is the sampled chunk itself.  Every case is labeled
``synthetic: true`` with its construction method — these are evaluation
probes, NEVER real learner data and NEVER training data.

Hand-written paraphrase probes (mode ``hand_paraphrase``) live in the
committed dataset file alongside the generated ones; they were authored
by reading the target chunks and phrasing natural learner questions.

Deterministic: same corpus -> byte-identical dataset (sorted sampling,
fixed strides, no randomness).

Usage:
    python -m mlrag.evaluation.build_gate22_eval_dataset
"""

from __future__ import annotations

import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
CORPUS_PATH = REPO_ROOT / "mlrag" / "artifacts" / "gate21_corpus.json"
DATASET_PATH = (REPO_ROOT / "mlrag" / "evaluation"
                / "gate22_hf_eval_dataset.json")

CONSTRUCTION_METHOD = (
    "extractive: query = chunk title + first body sentence "
    "(verbatim substring); relevant = the sampled chunk itself; "
    "scope = the chunk's own subject/topic; synthetic evaluation probe"
)

_SENT = re.compile(r"(.+?[.!?])(\s|$)", re.DOTALL)


def first_body_sentence(text: str, title: str | None) -> str:
    """First sentence that is not the title context line."""
    lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    body = " ".join(ln for ln in lines
                    if title is None or ln != title.strip())
    match = _SENT.match(body)
    if match:
        return match.group(1).strip()
    return body[:160].strip()


def stride_sample(ids: list[str], want: int) -> list[str]:
    """Deterministic stride sampling over sorted ids."""
    if want >= len(ids):
        return list(ids)
    step = len(ids) / want
    picked: list[str] = []
    for i in range(want):
        candidate = ids[int(i * step)]
        if candidate not in picked:
            picked.append(candidate)
    return picked


def build_extractive(chunks: list[dict]) -> list[dict]:
    by_table: dict[str, list[dict]] = {}
    for chunk in chunks:
        by_table.setdefault(chunk["source_table"], []).append(chunk)
    plan = (("lessons", 8), ("questions", 12), ("topics", 10))
    cases: list[dict] = []
    seq = 0
    for table, want in plan:
        rows = sorted(by_table.get(table, []), key=lambda c: c["chunk_id"])
        for row in [r for i in stride_sample([r["chunk_id"] for r in rows],
                                             want)
                    for r in rows if r["chunk_id"] == i]:
            seq += 1
            title = row.get("title") or ""
            if table == "questions":
                first_line = row["text"].splitlines()[0]
                query = first_line[len("Question: "):] if first_line.startswith(
                    "Question: ") else first_line
                mode = "extractive_question_stem"
            elif table == "topics":
                query = f"{title}. {first_body_sentence(row['text'], title)}"
                mode = "extractive_topic_lead"
            else:
                query = f"{title}. {first_body_sentence(row['text'], title)}"
                mode = "extractive_lesson_lead"
            cases.append({
                "case_id": f"g22-e{seq:02d}",
                "mode": mode,
                "synthetic": True,
                "construction": CONSTRUCTION_METHOD,
                "query": query.strip(),
                "relevant_chunk_ids": [row["chunk_id"]],
                "subject_id": row["subject_id"],
                "topic_id": row["topic_id"],
                "difficulty": row["difficulty"],
                "source": f"gate21 chunk {row['chunk_id']}",
                "rationale": ("Query is a verbatim extract of the target "
                              "chunk; a correct retriever ranks the source "
                              "chunk at the top within subject scope."),
            })
    return cases


#: Hand-authored natural-learner paraphrase probes (mode hand_paraphrase).
#: Each was written by reading the target chunk's actual text and phrasing
#: the question a learner would ask; each is answerable ONLY by its target
#: chunk.  Labeled synthetic, never learner data, never training data.
HAND_PARAPHRASE: tuple[dict[str, object], ...] = (
    {
        "query": "Why should I declare variables with the narrowest "
                 "correct type, and when is it better to let the compiler "
                 "infer the type instead?",
        "relevant_chunk_ids":
            ["lessons:33333333-3333-3333-3333-333333333311:summary#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111101",
        "topic_id": "22222222-2222-2222-2222-222222222211",
        "difficulty": "EASY",
        "rationale": "Target summary chunk states: narrowest correct type, "
                     "prefer inference locally, explicit at boundaries.",
    },
    {
        "query": "How does a router decide where to forward a packet, and "
                 "what happens when no route in its table matches?",
        "relevant_chunk_ids":
            ["lessons:33333333-3333-3333-3333-333333333316#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111102",
        "topic_id": "22222222-2222-2222-2222-222222222216",
        "difficulty": "MEDIUM",
        "rationale": "Target chunk states longest-prefix match forwarding "
                     "plus drop/default-gateway fallback.",
    },
    {
        "query": "Why is switching between threads cheaper than switching "
                 "between processes, and what danger does their shared "
                 "memory create?",
        "relevant_chunk_ids":
            ["lessons:33333333-3333-3333-3333-333333333332#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111104",
        "topic_id": "22222222-2222-2222-2222-222222222232",
        "difficulty": "EASY",
        "rationale": "Target chunk states shared address space -> cheaper "
                     "switches but requires synchronization against races.",
    },
    {
        "query": "Does type inference mean my variables have no type until "
                 "the program runs?",
        "relevant_chunk_ids":
            ["questions:44444444-4444-4444-4444-444444444402#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111101",
        "topic_id": "22222222-2222-2222-2222-222222222211",
        "difficulty": "EASY",
        "rationale": "Target explanation states inference is compile-time "
                     "deduction from the initializer, not dynamic typing.",
    },
    {
        "query": "Which data structure does breadth-first search use to "
                 "visit nodes level by level, and how does depth-first "
                 "search differ?",
        "relevant_chunk_ids":
            ["questions:44444444-4444-4444-4444-444444444482#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111105",
        "topic_id": "22222222-2222-2222-2222-222222222243",
        "difficulty": "MEDIUM",
        "rationale": "Target explanation states BFS level-by-level via "
                     "queue and DFS via stack.",
    },
    {
        "query": "What do you call the role that turns raw data into "
                 "business decisions?",
        "relevant_chunk_ids":
            ["questions:44444444-4444-4444-4444-444444444541#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111110",
        "topic_id": "22222222-2222-2222-2222-222222222330",
        "difficulty": "EASY",
        "rationale": "Target explanation states analysts turn data into "
                     "decisions; distractors are unrelated roles.",
    },
    {
        "query": "Starting from the element itself and moving outward, "
                 "what are the four layers of the CSS box model in order?",
        "relevant_chunk_ids":
            ["questions:44444444-4444-4444-4444-444444444599#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111108",
        "topic_id": "22222222-2222-2222-2222-222222222289",
        "difficulty": "EASY",
        "rationale": "Target explanation states content innermost, then "
                     "padding, border, and margin.",
    },
    {
        "query": "How does a program decide what to do next using "
                 "branching and loops?",
        "relevant_chunk_ids":
            ["topics:22222222-2222-2222-2222-222222222212#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111101",
        "topic_id": "22222222-2222-2222-2222-222222222212",
        "difficulty": "EASY",
        "rationale": "Target topic covers if/else branching, pattern "
                     "matching, for/while iteration and early exits.",
    },
    {
        "query": "Where do the conceptual classes and associations in a "
                 "domain model come from?",
        "relevant_chunk_ids":
            ["topics:22222222-2222-2222-2222-222222222279#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111107",
        "topic_id": "22222222-2222-2222-2222-222222222279",
        "difficulty": "MEDIUM",
        "rationale": "Target topic states the domain model is derived from "
                     "use cases via conceptual classes and associations.",
    },
    {
        "query": "What mathematical rule drives weight updates while a "
                 "neural network trains?",
        "relevant_chunk_ids":
            ["topics:22222222-2222-2222-2222-222222222328#c0"],
        "subject_id": "11111111-1111-1111-1111-111111111109",
        "topic_id": "22222222-2222-2222-2222-222222222328",
        "difficulty": "HARD",
        "rationale": "Target topic states chain-rule flow, weight updates "
                     "and the training loop (backpropagation).",
    },
)

HAND_CONSTRUCTION = (
    "hand-authored paraphrase: question phrased by the implementer after "
    "reading the target chunk; answerable by that chunk; synthetic "
    "evaluation probe"
)


def build_hand_paraphrase() -> list[dict]:
    """Materialize committed paraphrase probes with stable case ids."""
    cases: list[dict] = []
    for seq, probe in enumerate(HAND_PARAPHRASE, start=1):
        case = dict(probe)
        case.update({
            "case_id": f"g22-p{seq:02d}",
            "mode": "hand_paraphrase",
            "synthetic": True,
            "construction": HAND_CONSTRUCTION,
            "source": ("gate21 chunk "
                       f"{probe['relevant_chunk_ids'][0]}"),  # type: ignore[index]
        })
        cases.append(case)
    return cases


def main() -> dict:
    raw = json.loads(CORPUS_PATH.read_text(encoding="utf-8"))
    chunks = sorted(raw["chunks"], key=lambda c: c["chunk_id"])
    dataset = {
        "dataset": "gate22_hf_retrieval_eval",
        "version": "1",
        "corpus_fingerprint": raw["fingerprint"],
        "corpus_size": len(chunks),
        "synthetic_note": ("ALL queries are synthetic evaluation probes "
                           "derived from corpus text; none are real learner "
                           "queries and none may be used as training data."),
        "cases": build_extractive(chunks) + build_hand_paraphrase(),
    }
    DATASET_PATH.write_text(
        json.dumps(dataset, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8")
    print(f"wrote {len(dataset['cases'])} cases -> {DATASET_PATH}")
    return dataset


if __name__ == "__main__":
    main()
