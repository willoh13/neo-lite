# NEO Operator Tools

Optional, standalone tools that ship with NEO Operator. Each is a pure-Python scoring engine — no API keys, no cloud calls, no install beyond `pyyaml`.

## Tools

### 1. Delegation Scoring Matrix — model router

**Path:** `tools/delegation-scoring-matrix/`

Picks the best **AI model** for a task across 14 dimensions: reasoning depth, context size, output length, latency, cost ceiling, privacy locality, tool use, code quality, multimodal, factuality, language fluency, rate-limit pressure, auditability, brand-voice match.

**Quick start:**

```bash
cd tools/delegation-scoring-matrix
python3 router.py --task-preset content_draft     # → openrouter:x-ai/grok-2
python3 router.py --task-preset hard_debug        # → openrouter:deepseek/deepseek-r1
python3 router.py --list-presets
python3 router.py --list-models
```

**Tuning:** edit `config.yaml`. Add models, change capability scores, adjust dimension weights, add task presets — all without touching code.

**Use case:** every NEO sub-agent that calls an LLM should route through this instead of hardcoding a model. When you want to add a new model or shift to cheaper providers, you change one file.

### 2. Language Selection Matrix — language router

**Path:** `tools/language-selection-matrix/`

Picks the best **programming language** for a coding task across 14 dimensions: raw performance, memory safety, ease of development, AI/ML ecosystem, numerical computing, web frontend, backend API, systems programming, concurrency, library ecosystem, production maintainability, hardware level, learning ease, security risk.

**Quick start:**

```bash
cd tools/language-selection-matrix
python3 language-router.py --task-preset ai_pipeline          # → python
python3 language-router.py --task-preset web_frontend        # → typescript
python3 language-router.py --task-preset performance_critical # → rust
python3 language-router.py --zero-install --scores '{...}'   # → bash
```

**Tuning:** edit `config.yaml`. Same pattern as the model router.

**Use case:** when an AI sub-agent or human developer needs to decide what language to write a piece of code in, this gives a defensible answer based on weighted scoring, not vibes.

## How they work together

Both tools use the same scoring pattern (adapted from the AIDA framework):

1. Score the task 0–3 on each of 14 dimensions (configurable weights)
2. Score each candidate (model or language) 0–4 on the same dimensions
3. Weighted sum → highest wins
4. Hard constraints filter ineligible candidates first
5. Tie-breakers resolve close scores (cheaper, more local, faster)

**Combined example (NTO workflow):**

```bash
# Pick the language for the task
python3 tools/language-selection-matrix/language-router.py --task-preset backend_api
# → go

# Pick the model that will write it
python3 tools/delegation-scoring-matrix/router.py --task-preset tech_research
# → openrouter:deepseek/deepseek-chat

# Verify resource footprint (NTO's "Gortex Rule")
free -h
df -h /
```

## Installation

### Inside NEO Operator (already there)

Both tools are pre-installed in the Docker container at `/opt/hermes/tools/`. Just `cd /opt/hermes/tools/delegation-scoring-matrix` and run.

### Standalone install

```bash
git clone https://github.com/willoh13/neo-operator.git
cd neo-operator/tools/delegation-scoring-matrix
pip install pyyaml
python3 router.py --list-models
```

Requires Python 3.8+ and PyYAML. No other dependencies. No internet needed after install. Runs entirely offline.

## Customizing for your stack

The model registry in `config.yaml` is opinionated — it has the models NEO uses today. To add your own:

1. Open `tools/delegation-scoring-matrix/config.yaml`
2. Add your model under `models:` with the same structure
3. Score it 0–4 on each of the 14 dimensions
4. Restart — no code changes needed

Same for adding languages (`tools/language-selection-matrix/config.yaml`).

## Honest limits

- **Static scoring, not learned.** Doesn't observe past task success. Tune weights manually when patterns emerge.
- **Brand voice and "easy for Will" are opinionated weights.** If you hire Rust devs, change `learning_ease` weight.
- **Tie-breakers are heuristic.** Edge cases may surprise you. Use `--explain` to see the full breakdown.
- **Config resolution is best-effort.** If your config is in a custom location, use `--config PATH` explicitly.

## License

MIT — same as NEO Operator.