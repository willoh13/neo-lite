#!/usr/bin/env python3
"""
NEO Language Selection Router — picks the best language for a coding task.

Companion to delegation-scoring-matrix/router.py. Same scoring pattern,
but instead of picking a model tier, it picks a programming language
(Python / TypeScript / Rust / Go / Bash).

Usage:
    python3 language-router.py --task-preset ai_pipeline
    python3 language-router.py --scores '{"ai_ml_ecosystem": 3, "ease_of_development": 3, ...}'
    python3 language-router.py --list-languages
    python3 language-router.py --list-presets

Scoring (same as delegation router):
    weighted_score(language, task) =
        Σ (language.capability[dim] × task_score[dim] × dim_weight)
        for each of 14 dimensions

Hard constraints (different from model router — task-driven):
    - If task needs AI/ML → Python only
    - If task needs browser UI → TypeScript only
    - If task must run without install → Bash only

Config resolution: searches these locations in order
  1. /opt/hermes/tools/language-selection-matrix/config.yaml (NEO Operator Docker)
  2. <same dir as this router.py>/config.yaml (when shipped with product)
  3. ~/.hermes/skills/.../config.yaml (Will's N-Suite dev env)
Override with --config PATH.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(2)

# ─── Defaults ────────────────────────────────────────────────────────────────

DEFAULT_CONFIG_CANDIDATES = [
    # Inside NEO Operator Docker container
    Path("/opt/hermes/tools/language-selection-matrix/config.yaml"),
    # Alongside the router.py (when shipped with the product)
    Path(__file__).parent / "config.yaml",
    # Will's personal N-Suite (your dev env)
    Path.home() / ".hermes/skills/autonomous-ai-agents/delegation-scoring-matrix/language-config.yaml",
]


def resolve_default_config() -> Path:
    """Find the first existing config from the candidate paths."""
    for candidate in DEFAULT_CONFIG_CANDIDATES:
        if candidate.exists():
            return candidate
    # Fallback: use the first candidate (will trigger _emergency_config if missing)
    return DEFAULT_CONFIG_CANDIDATES[0]


DEFAULT_CONFIG = resolve_default_config()

DIMENSIONS = [
    "raw_performance", "memory_safety", "ease_of_development", "ai_ml_ecosystem",
    "numerical_computing", "web_frontend", "backend_api", "systems_programming",
    "concurrency", "library_ecosystem", "production_maint", "hardware_level",
    "learning_ease", "security_risk",
]


def load_config(path: Path = DEFAULT_CONFIG) -> dict:
    if not path.exists():
        return _emergency_config()
    with path.open() as f:
        return yaml.safe_load(f) or {}


def _emergency_config() -> dict:
    return {
        "dimension_weights": {d: 1.0 for d in DIMENSIONS},
        "hard_constraints": {},
        "tie_breakers": ["prefer_python"],
        "languages": [],
        "task_presets": {},
    }


# ─── Scoring ─────────────────────────────────────────────────────────────────

def compute_score(language: dict, task_scores: dict, weights: dict) -> float:
    score = 0.0
    caps = language.get("capabilities", {})
    for dim in DIMENSIONS:
        score += caps.get(dim, 0) * task_scores.get(dim, 0) * weights.get(dim, 1.0)
    return score


def passes_constraints(language: dict, task: dict, constraints: dict) -> tuple[bool, str | None]:
    lang_id = language["id"]
    task_scores = task.get("scores", {})

    # AI/ML ecosystem critical → Python required
    if constraints.get("block_non_python_when_ai_required", True):
        if task_scores.get("ai_ml_ecosystem", 0) >= 3 and lang_id != "python":
            return False, "AI/ML required (ai_ml_ecosystem>=3) — Python only"

    # Browser UI critical → TypeScript required
    if constraints.get("block_non_web_lang_when_browser_ui", True):
        if task_scores.get("web_frontend", 0) >= 3 and lang_id not in ("typescript",):
            return False, "Browser UI required (web_frontend>=3) — TypeScript only"

    # Must run without install → Bash only
    if constraints.get("force_bash_when_zero_install", True):
        if task.get("zero_install_required") and lang_id != "bash":
            return False, "Must run without install — Bash only"

    # No runtime deps requested → Bash
    if task.get("zero_install_required") and lang_id != "bash":
        return False, "zero_install_required → Bash only"

    return True, None


def apply_tie_breakers(a: dict, b: dict, breakers: list[str]) -> int:
    """Returns -1 if a wins, +1 if b wins, 0 if still tied."""
    for breaker in breakers:
        if breaker == "prefer_python":
            if a["id"] == "python":
                return -1
            if b["id"] == "python":
                return 1
        elif breaker == "prefer_more_lindy":
            la = a.get("lindy_years", 0)
            lb = b.get("lindy_years", 0)
            if la > lb:
                return -1
            if lb > la:
                return 1
        elif breaker == "prefer_fewer_runtime_deps":
            sa = a.get("runtime_size_mb", 999)
            sb = b.get("runtime_size_mb", 999)
            if sa < sb:
                return -1
            if sb < sa:
                return 1
    return 0


# ─── Main router ─────────────────────────────────────────────────────────────

def route(task: dict, config: dict | None = None) -> dict:
    cfg = config or load_config()
    weights = cfg.get("dimension_weights", {})
    constraints = cfg.get("hard_constraints", {})
    breakers = cfg.get("tie_breakers", [])
    languages = cfg.get("languages", [])

    task_scores = task.get("scores", {})

    ranked: list[tuple[float, dict]] = []
    blocked: list[tuple[dict, str]] = []

    for lang in languages:
        ok, reason = passes_constraints(lang, task, constraints)
        if not ok:
            blocked.append((lang, reason))
            continue
        score = compute_score(lang, task_scores, weights)
        ranked.append((score, lang))

    ranked.sort(key=lambda x: x[0], reverse=True)

    # Resolve ties (5% threshold)
    if len(ranked) >= 2:
        for i in range(len(ranked) - 1):
            a_score, a_lang = ranked[i]
            b_score, b_lang = ranked[i + 1]
            if b_score > 0 and (a_score - b_score) / max(a_score, 1) < 0.05:
                tb = apply_tie_breakers(a_lang, b_lang, breakers)
                if tb > 0:
                    ranked[i], ranked[i + 1] = ranked[i + 1], ranked[i]

    return {
        "winner": ranked[0][1] if ranked else None,
        "winner_score": ranked[0][0] if ranked else 0,
        "ranked": [{"language": m["id"], "tier": m["tier"], "score": round(s, 2)} for s, m in ranked[:5]],
        "blocked": [{"language": m["id"], "reason": r} for m, r in blocked],
    }


# ─── CLI ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="NEO language selection router")
    parser.add_argument("--task-preset", help="Name of a task preset")
    parser.add_argument("--scores", help="JSON dict of 14-dim scores (0-3)")
    parser.add_argument("--zero-install", action="store_true", help="Force Bash (no install allowed)")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--explain", action="store_true")
    parser.add_argument("--list-languages", action="store_true")
    parser.add_argument("--list-presets", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    cfg = load_config(args.config)

    if args.list_languages:
        print(f"{'Lang':<12} {'Tier':<5} {'Runtime MB':<12} {'Lindy yrs':<10}")
        print("-" * 50)
        for lang in cfg.get("languages", []):
            print(f"{lang['id']:<12} {lang['tier']:<5} {lang['runtime_size_mb']:<12} {lang['lindy_years']:<10}")
        return

    if args.list_presets:
        print("Available task presets:")
        for name in (cfg.get("task_presets") or {}).keys():
            print(f"  - {name}")
        return

    if not args.task_preset and not args.scores:
        parser.error("Provide --task-preset NAME or --scores '{...}'")

    if args.task_preset:
        preset = cfg.get("task_presets", {}).get(args.task_preset)
        if not preset:
            print(f"ERROR: preset '{args.task_preset}' not found.", file=sys.stderr)
            print(f"Available: {list(cfg.get('task_presets', {}).keys())}", file=sys.stderr)
            sys.exit(1)
        scores = preset
    else:
        scores = json.loads(args.scores)

    task = {"scores": scores}
    if args.zero_install:
        task["zero_install_required"] = True

    if args.dry_run:
        result = route(task, cfg)
        if result["winner"]:
            print(f"[dry-run] Would route to: {result['winner']['id']} (score {result['winner_score']:.1f})")
        else:
            print("[dry-run] No language passed hard constraints.")
        return

    result = route(task, cfg)

    if args.explain:
        print(json.dumps(result, indent=2, default=str))
    else:
        if result["winner"]:
            print(result["winner"]["id"])
        else:
            print("NONE", file=sys.stderr)
            sys.exit(1)


if __name__ == "__main__":
    main()