---
name: language-selection-matrix
description: Score-based language router — picks the best programming language (Python, TypeScript, Rust, Go, Bash) for a coding task across 14 dimensions (performance, safety, AI/ML, web, concurrency, learning ease). Configurable YAML, no code changes needed.
version: 1.0.0
author: NEO
metadata:
  router: delegation-scoring-matrix/language-router.py
  config: delegation-scoring-matrix/language-config.yaml
---

# Language Selection Matrix

Companion to the **delegation-scoring-matrix**. Same scoring pattern, but instead of picking a *model tier*, it picks a *programming language* for a coding task.

Adapted from AIDA's "Query Logic Agent" framework, repurposed for NEO's actual stack: **Python, TypeScript, Rust, Go, Bash**.

## Files

| File | Purpose |
|---|---|
| `language-config.yaml` | 14 dimensions, weights, language registry, task presets. **Edit this, not the code.** |
| `language-router.py` | Scoring engine. Loads config, applies hard constraints, weighted-sum, tie-breakers. |

## The 14 dimensions

| # | Dimension | What it measures |
|---|---|---|
| 1 | `raw_performance` | Speed of execution matters? |
| 2 | `memory_safety` | Guaranteed no UB / leaks required? |
| 3 | `ease_of_development` | Speed of iteration |
| 4 | `ai_ml_ecosystem` | numpy / torch / transformers / langchain needed? |
| 5 | `numerical_computing` | Linear algebra, scientific computing |
| 6 | `web_frontend` | Browser UI, JS interop |
| 7 | `backend_api` | REST/GraphQL/gRPC servers |
| 8 | `systems_programming` | Syscalls, file descriptors, raw bytes |
| 9 | `concurrency` | Async, threads, parallelism |
| 10 | `library_ecosystem` | Third-party packages available |
| 11 | `production_maint` | Long-term code clarity |
| 12 | `hardware_level` | Embedded, drivers, microcontrollers |
| 13 | `learning_ease` | Onboarding new devs (Will is non-technical — weighted high) |
| 14 | `security_risk` | Common vulnerabilities |

## Languages scored (0–4)

- **Python** — Will's home language. Default for AI/ML, scripting, glue, web backends.
- **TypeScript** — Browser UI, Node backends. Strong typing.
- **Rust** — Performance-critical, systems code. Memory-safe. Steep curve.
- **Go** — Simple, fast backends & CLI tools. Single static binary.
- **Bash** — Shell glue. No install required.

## Hard constraints (filter before scoring)

| Constraint | Effect |
|---|---|
| `block_non_python_when_ai_required` | If `ai_ml_ecosystem >= 3`, only Python qualifies |
| `block_non_web_lang_when_browser_ui` | If `web_frontend >= 3`, only TypeScript qualifies |
| `force_bash_when_zero_install` | If `--zero-install` flag is set, only Bash qualifies |

## Tie-breakers

When two languages score within 5%:
1. `prefer_python` — Will's home language
2. `prefer_more_lindy` — Older / more stable = lower risk
3. `prefer_fewer_runtime_deps` — Less to install

## Usage

### From the CLI

```bash
# Use a preset
python3 language-router.py --task-preset ai_pipeline
python3 language-router.py --task-preset web_scraper

# Ad-hoc scoring (0-3 per dimension)
python3 language-router.py --scores '{"ai_ml_ecosystem": 3, "ease_of_development": 2, "backend_api": 2}'

# Force bash (no install allowed)
python3 language-router.py --zero-install --scores '{"ease_of_development": 2, "systems_programming": 1}'

# Inventory
python3 language-router.py --list-languages
python3 language-router.py --list-presets

# Explain the decision
python3 language-router.py --task-preset cli_tool --explain
```

### From Python

```python
from language_router import route, load_config

cfg = load_config()
result = route({
    "scores": cfg["task_presets"]["ai_pipeline"],
}, cfg)

print(result["winner"]["id"])  # "python"
```

### From NTO (Neural Technology Officer)

NTO's job is to vet tech decisions. When evaluating a coding task:

```bash
# 1. Pick the language
python3 language-router.py --task-preset ai_pipeline
# → python

# 2. Confirm the model that will run it
python3 router.py --task-preset tech_research
# → openrouter:deepseek/deepseek-chat

# 3. Vet resource footprint (NTO's Gortex Rule)
free -h
df -h /
```

## Task presets (built-in)

| Preset | Winner | When |
|---|---|---|
| `quick_script` | python | One-off automation, throwaway |
| `ai_pipeline` | python | AI/ML work (forced by hard constraint) |
| `web_frontend` | typescript | React/Vue/Svelte components |
| `backend_api` | go | Fast microservices, REST endpoints |
| `cli_tool` | go | Static binary, ship to users |
| `performance_critical` | rust | Parsers, kernels, hot paths |
| `systems_code` | rust | Drivers, daemons, low-level OS |
| `cron_glue` | python | Scheduled tasks (NEO env has Python) |
| `web_scraper` | python | Browser automation, crawling |
| `data_analysis` | python | Notebooks, pandas, exploration |

## Tuning guide

**You want to push more toward Python (Will's comfort)?**
- Bump `learning_ease` weight (already at 1.5)
- Move `prefer_python` to top of tie-breakers

**You want to deprioritize Rust (Will doesn't know it)?**
- Lower `learning_ease` weight won't help — Rust scores low on that anyway
- Lower Rust's tier from 3 → 4 in `languages:`

**You want to add a new language (e.g., Zig)?**
- Add it under `languages:` with scores for all 14 dimensions
- Set tier, runtime size, lindy years
- Update `tie_breakers` if you want to favor it

**You want a new task preset (e.g., `embedded_firmware`)?**
- Add it under `task_presets:`
- Score all 14 dimensions 0-3

## Pitfalls

- **`learning_ease` weight is opinionated** — set to 1.5 because Will is non-technical. If you hire devs who know Rust, lower it.
- **Hard constraints are absolute** — they filter before scoring, not on score. A 0-score Python still wins over a 100-score Rust if AI/ML is required.
- **Don't add C++ to this matrix** — Will doesn't know it, and the matrix is for NEO's actual stack. If you need C++, you're working on a different project entirely.
- **Bash for cron is sometimes wrong** — if you have Python available and need complex logic, Python is faster to write. Bash is for "run X every 5 minutes without installing anything."

## Honest limits

This is the same scoring approach as the model router — it's a static function, not a learned system. It doesn't observe past project success and adjust. If a Python project keeps failing, the matrix won't notice. Add a log of `(task_preset, language, project_success)` and tune weights from real data when you have enough samples.

The tie-breakers are opinionated. `prefer_python` will favor Python even when Rust is technically better — that's deliberate because Will's velocity matters more than marginal performance gains. If you hire a Rust dev, move `prefer_python` down.