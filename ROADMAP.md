# NEO Operator Roadmap

Public roadmap for NEO Operator. We share this openly because customers deserve to know where the product is heading, and contributors deserve to know what to build.

**Status legend:** ✅ shipped · 🚧 in progress · ⏳ planned · 💭 considering

---

## Phase 1 — Foundation ✅ Shipped 2026-06-27

The core product works.

- ✅ Docker Compose stack (single command deploy)
- ✅ First-run wizard (3 questions, knows who you are)
- ✅ License system (free tier + paid tiers)
- ✅ Persistent memory across sessions
- ✅ 6 API providers supported (DeepSeek, OpenAI, Anthropic, Gemini, xAI, Ollama)
- ✅ NEO-Scraper Part (web research, batch mode, news watcher)
- ✅ **Tools:** `tools/delegation-scoring-matrix/` — score-based model router, 14 dimensions, 8 models, 6 task presets
- ✅ **Tools:** `tools/language-selection-matrix/` — score-based language router, 14 dimensions, 5 languages, 10 task presets

---

## Phase 2 — Adaptive Intelligence 🚧 In Progress

The routers learn from real usage instead of being tuned by hand.

### 🚧 Adaptive Scoring Layer

**Goal:** Every routing decision gets logged. Outcomes get scored. Weights self-tune from real data.

**How it works:**

1. **Log every decision.** When the model router picks Grok for `content_draft`, log `(preset, model, task_input_tokens, task_output_tokens, timestamp, success_score)`.
2. **Score outcomes.** After each task, the user (or an automated signal) rates output quality 0–10. Success = output met the task's acceptance criteria.
3. **Tune weights.** A small learning loop runs weekly: for each dimension, compute the correlation between (model_capability × task_need × weight) and outcome_score. Increase weight on dimensions where high scores predict success; decrease on dimensions that don't.
4. **Close the loop.** New weights flow back into `config.yaml` automatically. The next routing decision uses them.

**Why this matters:** Today, weights are opinionated (e.g., `brand_voice_match: 1.5` because I think brand voice matters). After 100+ real tasks, weights become empirical (e.g., `brand_voice_match: 1.3, factuality: 1.7` because the data says factuality predicts satisfaction better than voice does).

**Files to add:**
- `tools/delegation-scoring-matrix/adaptive.py` — learning loop
- `tools/delegation-scoring-matrix/outcomes.csv` — append-only log
- `tools/delegation-scoring-matrix/weight-history.json` — weight evolution over time

**Estimated scope:** ~200 lines, no ML deps. Pure statistics: regression on the outcome matrix.

### 💭 Live Quota Awareness

**Goal:** When a model's API is rate-limited or down, automatically reroute to the next-best.

**How it works:**

1. Wrap each model call with a quota-check layer
2. On 429 (rate limited) or 5xx (down), read the rate-limit-reset header
3. Until reset, exclude that model from routing candidates
4. Optionally add an "API health" task preset that always picks the cheapest available model

**Files to add:**
- `tools/delegation-scoring-matrix/quota.py` — live quota tracking
- `tools/delegation-scoring-matrix/health.json` — current state per provider

**Estimated scope:** ~150 lines, depends on provider APIs exposing headers.

---

## Phase 3 — Memory & Multi-Agent 💭 Planned

The routers share knowledge across runs and coordinate with each other.

### 💭 Cognee Memory Integration

**Goal:** Replace flat memory files with a real knowledge graph that the routers can query.

**Why Cognee:** Open-source, builds knowledge graphs from text + code + conversations. NEO already runs lots of tools; Cognee turns their outputs into a queryable graph.

**How it works:**

1. Every N-Suite officer's output gets ingested into Cognee
2. The model router asks Cognee: "Has this task type worked before? What worked?"
3. The language router asks Cognee: "What languages have we shipped in this codebase?"
4. Past decisions inform current routing — not just static weights, but real outcomes

**Files to add:**
- `tools/memory-bridge/cognee.py` — adapter
- `tools/memory-bridge/decision-log.md` — human-readable trail

**Estimated scope:** ~300 lines, depends on Cognee API stability.

### 💭 Cross-Router Coordination

**Goal:** The model router and language router share a state. When language router picks Rust, model router can bias toward models known to write better Rust.

**How it works:**

1. After every routing decision, log `(task_type, language, model, outcome)`
2. Build a small lookup: "for this language, which models historically scored highest?"
3. At routing time, add a 15th dimension: `model_x_language_track_record`

**Estimated scope:** ~100 lines. Builds on Phase 2's outcome log.

### 💭 More Language Presets

As users ship more task types, the language preset list grows. Candidates so far:

- ⏳ `embedded_firmware` — microcontroller code
- ⏳ `data_etl` — pipeline orchestration
- ⏳ `cli_daemon` — long-running CLI processes
- ⏳ `gpu_kernel` — CUDA / ROCm compute
- ⏳ `webhook_handler` — small HTTP endpoints

Add via PR — YAML-only changes, no code.

---

## Out of Scope

We're not building these (yet):

- ❌ A GUI dashboard for tuning weights — YAML is the dashboard
- ❌ Model hosting — we use existing APIs (OpenRouter, etc.)
- ❌ Custom model training — too expensive, low ROI for our users
- ❌ Mobile app — NEO Operator is a Docker container, run it anywhere Docker runs

---

## How to Contribute

- **Add a model to the registry:** edit `tools/delegation-scoring-matrix/config.yaml`. Score it on the 14 dimensions.
- **Add a language:** edit `tools/language-selection-matrix/config.yaml`.
- **Add a task preset:** add it under `task_presets:` in either config.
- **File an issue:** https://github.com/willoh13/neo-operator/issues
- **PRs welcome:** keep changes scoped to one file (a config + a doc).

---

## License

MIT — same as the rest of NEO Operator.