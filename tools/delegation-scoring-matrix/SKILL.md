---
name: delegation-scoring-matrix
description: Score-based model router — picks the best model for a task across 14 dimensions (reasoning, cost, latency, privacy, brand voice, etc). Configurable YAML, no code changes needed to tune.
version: 1.0.0
author: NEO
metadata:
  router: delegation-scoring-matrix/router.py
  config: delegation-scoring-matrix/config.yaml
---

# Delegation Scoring Matrix

A scoring-based **model router**. Every incoming task gets a 0-3 score across 14 dimensions; each model has a 0-4 capability on those same dimensions; multiply, weight, sum → pick the winner. Hard constraints filter first (privacy, cost ceiling, latency, context size).

Adapted from AIDA's "Query Logic Agent" framework, repurposed from language selection to **model tier selection** — which is what NEO actually needs.

## Companion file: Language Selection Matrix

Same scoring pattern, different problem. Use it to pick a **programming language** for a coding task (Python / TypeScript / Rust / Go / Bash) instead of a model tier. See [`LANGUAGE-SELECTION.md`](./LANGUAGE-SELECTION.md) and `language-router.py`.

NTO (Neural Technology Officer) uses both routers together: pick the language with `language-router.py`, pick the model with `router.py`, then vet the resource footprint.

## Why this exists

Today, NEO sub-agents (NOO, NFO, NTO, NMO, NRO) hardcode their model assignment in each skill file. That's brittle:
- A new model comes out → edit every skill
- Cost ceiling shifts → edit every skill
- A task is "harder than usual" → still hits the cheap model

This router centralizes that decision in **one YAML file**. Edit scores, weights, or hard constraints → all of NEO picks better models.

## Files

| File | Purpose |
|---|---|
| `config.yaml` | The 14 dimensions, weights, model registry, task presets. **Edit this, not the code.** |
| `router.py` | Pure-function scorer. Loads config, applies hard constraints, weighted-sum, tie-breakers. |
| `language-config.yaml` | Companion: 14 dimensions for **language** selection (Python/TS/Rust/Go/Bash). |
| `language-router.py` | Companion: scoring engine for language selection. |
| `LANGUAGE-SELECTION.md` | Companion: usage + tuning guide for language router. |
| `references/testing-checklist.md` | **5 bugs caught during initial build + reusable verification recipe.** Read this before any config edit. |
| `references/repo-evaluation-methodology.md` | **How to honestly evaluate a third-party framework** (the AIDA pattern). Useful whenever Will asks "is this real?" |
| `references/bash-test-gotchas.md` | **Shell quoting traps** for test scripts (`$0.001` getting eaten, heredoc expansion, etc.). |

## The 14 dimensions

| # | Dimension | What it measures |
|---|---|---|
| 1 | `reasoning_depth` | Chain-of-thought, planning, multi-step logic |
| 2 | `context_size` | Input token count (>32k = high) |
| 3 | `output_length` | Expected response size |
| 4 | `latency` | How fast the user is waiting |
| 5 | `cost_ceiling` | Hard $/task budget |
| 6 | `privacy_locality` | Must NOT leave the machine |
| 7 | `tool_use` | Function calling / structured output |
| 8 | `code_quality` | Programming task |
| 9 | `multimodal` | Vision/audio input |
| 10 | `factuality` | Hallucination risk tolerance (high = needs accurate) |
| 11 | `language_fluency` | Non-English output |
| 12 | `rate_limit_pressure` | Many parallel calls expected |
| 13 | `auditability` | Needs reproducible / deterministic |
| 14 | `brand_voice_match` | Must match existing content style |

## Task scoring (0-3)

- **3** = critical, must be met (e.g., privacy_locality: 3 = MUST be local)
- **2** = important
- **1** = nice-to-have
- **0** = irrelevant for this task

## Model scoring (0-4)

- **4** = excellent at this dimension
- **3** = good
- **2** = adequate
- **1** = poor
- **0** = can't do it

## Hard constraints (gate, don't score)

These filter models **before** scoring. A model that violates any constraint is excluded regardless of weighted score.

- `block_remote_when_local_required`: if task.privacy_locality = 3, only local models qualify
- `max_cost_per_task_usd`: estimated cost must be under this
- `max_latency_seconds`: model must respond faster than this
- Context size: input must fit in model's max_context_tokens

## Tie-breakers

When two models score within 5% of each other, applied in order:
1. `prefer_cheaper` — lower $/1k wins
2. `prefer_local` — local > cloud
3. `prefer_lower_latency` — faster wins

## Usage

### From the CLI

```bash
# Use a preset (recommended)
python3 router.py --task-preset content_draft
python3 router.py --task-preset hard_debug --explain

# Ad-hoc scoring (0-3 per dimension)
python3 router.py --scores '{"reasoning_depth": 3, "factuality": 4, "output_length": 2, "latency": 2, "code_quality": 4, "brand_voice_match": 3}'

# Sanity check (no model call, just show routing decision)
python3 router.py --dry-run --task-preset hard_debug

# Inventory
python3 router.py --list-models
python3 router.py --list-presets
```

### From Python

```python
from router import route, load_config

cfg = load_config()
result = route({
    "scores": cfg["task_presets"]["content_draft"],
    "estimated_input_tokens": 4000,
    "estimated_output_tokens": 1500,
}, cfg)

print(result["winner"]["id"])  # "openrouter:deepseek/deepseek-chat"
print(result["ranked"])         # Top 5 with scores
```

### From a sub-agent

Each N-Suite skill should:
1. Load the config
2. Apply a preset OR override specific dimensions
3. Call the model ID returned by the router
4. Log the decision for later analysis

Example pattern (drop into a skill):
```python
from hermes_agent.skills.autonomous_ai_agents.delegation_scoring_matrix.router import route, load_config

def pick_model(task_description: str, preset: str = "content_draft", overrides: dict | None = None):
    cfg = load_config()
    scores = dict(cfg["task_presets"][preset])
    if overrides:
        scores.update(overrides)
    result = route({"scores": scores}, cfg)
    return result["winner"]["id"], result
```

## Task presets (built-in)

These map directly to your N-Suite:

| Preset | Maps to | Default winner |
|---|---|---|
| `ops_health_check` | NOO routine checks | `ollama:gemma4:e4b` |
| `financial_audit` | NFO cost/token accounting | `ollama:qwen3.6-mtp` (privacy-sensitive) |
| `tech_research` | NTO model eval / research | `openrouter:deepseek/deepseek-chat` |
| `content_draft` | NMO marketing copy | `openrouter:x-ai/grok-2` (brand voice match) |
| `web_research` | NRO web scanning | `openrouter:nvidia/llama-3.1-nemotron-70b-instruct` |
| `hard_debug` | Debugging / root cause | `openrouter:deepseek/deepseek-r1` |

## Tuning guide

**You want to push toward cheaper?**
- Increase `cost_ceiling` weight (line 30 of config)
- Lower `hard_constraints.max_cost_per_task_usd`
- Move `prefer_cheaper` to the top of `tie_breakers`

**You want more brand voice consistency?**
- Increase `brand_voice_match` weight
- Bump Grok capability on that dim from 4 → still 4 (it's already top)
- Lower other models' brand_voice_match scores

**You want to disable local models entirely?**
- In `hard_constraints`, set `block_remote_when_local_required: false` and the privacy check is skipped — but local models will still win on ties via `prefer_local`
- Remove the local models from `models:` list

**You want to add a new model?**
- Add it under `models:` in `config.yaml`
- Score all 14 dimensions 0-4
- Restart NEO (config is read at task time, so actually no restart needed)

**You want to add a new task preset?**
- Add it under `task_presets:`
- Score all 14 dimensions 0-3

## Verification

The canonical verification recipe lives in `references/testing-checklist.md` — read that file first. Quick version:

```bash
# Confirm it picks different models for different task types
for preset in ops_health_check financial_audit tech_research content_draft web_research hard_debug; do
  python3 router.py --task-preset $preset
done
```

Expected: a mix of tiers, with hard_debug → cloud premium, ops_health_check → local.

## Pitfalls

- **Don't set every dimension to 3.** If everything matters, nothing matters. Be ruthless: zero out anything irrelevant.
- **Use 0, not 1, for irrelevant dimensions.** A score of 1 means "nice-to-have" — that gets multiplied by the model's capability and the dimension weight, so even a small contribution can pull in a stronger (and more expensive) model. If a task doesn't need reasoning, score `reasoning_depth: 0`. This is what kept `ops_health_check` going to cloud models during initial testing — `reasoning_depth: 1` × `model_capability: 4` × `weight: 1.5` = 6 points of free contribution to DeepSeek.
- **The 5% tie threshold is a hack.** Two models with very different prices but similar weighted scores will still tie if within 5%. If this matters, tighten the threshold (line ~190 of router.py).
- **`estimated_input_tokens` matters.** Without it, hard constraint cost ceiling is skipped. Estimate roughly.
- **Local models on `qwen3.6-mtp` and `gemma4:e4b` assume Ollama is running.** If Ollama is down, the router will still pick them — caller's responsibility to handle the failure.
- **`passes_hard_constraints` reads privacy from `task.scores`, not `task` directly.** (Bug hit during initial build — privacy_locality=3 was being ignored because the check was looking at `task.get("privacy_locality")` instead of `task["scores"]["privacy_locality"]`.) Always test the hard-constraint path explicitly with a privacy=3 task before shipping.
- **High-capability models dominate when you add them.** Adding Gemini 2.0 Flash (multimodal=5, context_size=5) shifted `web_research` to Gemini because big-context wins — even though DeepSeek was the intended pick. When adding a new model, re-run all presets and check the rankings didn't drift.
- **`brand_voice_match` matters more than its base weight.** A weight of 0.6 is too low — content_draft was picking DeepSeek over Grok until I bumped the weight to 1.5 AND bumped Grok's capability to 5. For tasks where output style matters, this dimension needs both a high weight AND high scores on the right models.

## Tuning sessions (real history)

When the router was first built, four tuning iterations were needed before presets picked sensible models:

1. **Initial:** All presets went to DeepSeek cloud. Local models scored too low.
2. **Bumped `cost_ceiling` weight** from 1.0 → 2.0 and dropped `ops_health_check.reasoning_depth` to 1. → ops + financial went local.
3. **Bumped `brand_voice_match` weight** 0.6 → 1.5 + Grok capability 4 → 5. → content_draft picked Grok over DeepSeek.
4. **Added Gemini 2.0 Flash** for multimodal + 1M context. → web_research now picks Gemini for big-context jobs.

**The lesson:** model registries aren't write-once. Tune iteratively. After every change, re-run all presets AND ad-hoc edge cases (privacy=3, latency=4, multimodal=3) to confirm nothing regressed.

## Verification recipe (run after every config change)

```bash
# All 6 presets must pick sensible models
for preset in ops_health_check financial_audit tech_research content_draft web_research hard_debug; do
  python3 router.py --task-preset $preset
done

# Hard-constraint path
python3 router.py --scores '{"reasoning_depth": 2, "factuality": 3, "privacy_locality": 3, "cost_ceiling": 3}'
# Expected: local model (privacy=3 forces it)

# Latency-critical
python3 router.py --scores '{"reasoning_depth": 1, "latency": 4, "cost_ceiling": 3, "output_length": 1}'
# Expected: gemma4:e4b (local, 0.8s) or Gemini Flash (~2s)

# Multimodal
python3 router.py --scores '{"reasoning_depth": 2, "multimodal": 3, "factuality": 2, "cost_ceiling": 2}'
# Expected: Gemini (only model with multimodal >= 3)

# Show full breakdown for the preset you just edited
python3 router.py --task-preset <name> --explain
```

If any of these regress, the config change broke something.

## Honest limits

This is **a scoring function, not a learned router.** It doesn't observe which models actually performed well on past tasks and adjust. A future iteration could log `(task_preset, model, output_quality_score)` and use that to fine-tune weights. For now, you tune the weights manually when you notice patterns.

The router also doesn't know about **rate limits in real-time** — it just uses static `rate_limit_pressure` capability scores. If you're hitting Grok's per-minute cap, the router won't reroute you. Add a layer that reads live API quota if you need that.