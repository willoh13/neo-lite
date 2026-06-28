#!/usr/bin/env python3
"""
NEO Delegation Scoring Router — picks the best model for a given task.

Usage:
    python3 router.py --task-preset content_draft
    python3 router.py --scores '{"reasoning_depth": 3, "factuality": 4, ...}'
    python3 router.py --preset content_draft --explain
    python3 router.py --list-models
    python3 router.py --dry-run --preset hard_debug

Scoring (adapted from AIDA's framework):
    weighted_score(model, task) =
        Σ (model.capability[dim] × task_score[dim] × dim_weight)
        for each of 14 dimensions

Hard constraints filter out ineligible models first.
Tie-breakers (cheaper, local, faster) pick the winner when scores are close.

Config resolution: searches these locations in order
  1. /opt/hermes/tools/delegation-scoring-matrix/config.yaml (NEO Lite Docker)
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
from typing import Any

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml", file=sys.stderr)
    sys.exit(2)

# ─── Defaults ────────────────────────────────────────────────────────────────

DEFAULT_CONFIG_CANDIDATES = [
    # Inside NEO Lite Docker container
    Path("/opt/hermes/tools/delegation-scoring-matrix/config.yaml"),
    # Alongside the router.py (when shipped with the product)
    Path(__file__).parent / "config.yaml",
    # Will's personal N-Suite (your dev env)
    Path.home() / ".hermes/skills/autonomous-ai-agents/delegation-scoring-matrix/config.yaml",
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
    "reasoning_depth", "context_size", "output_length", "latency",
    "cost_ceiling", "privacy_locality", "tool_use", "code_quality",
    "multimodal", "factuality", "language_fluency", "rate_limit_pressure",
    "auditability", "brand_voice_match",
]


# ─── Config loader ───────────────────────────────────────────────────────────

def load_config(path: Path = DEFAULT_CONFIG) -> dict:
    """Load YAML config. Falls back to a tiny in-memory default if file missing."""
    if not path.exists():
        return _emergency_config()
    with path.open() as f:
        return yaml.safe_load(f) or {}


def _emergency_config() -> dict:
    """Used only when the config file is missing — keeps the router runnable."""
    return {
        "dimension_weights": {d: 1.0 for d in DIMENSIONS},
        "hard_constraints": {
            "block_remote_when_local_required": True,
            "max_cost_per_task_usd": 1.0,
            "max_latency_seconds": 60,
        },
        "tie_breakers": ["prefer_cheaper", "prefer_local"],
        "models": [],
        "task_presets": {},
    }


# ─── Scoring ─────────────────────────────────────────────────────────────────

def compute_model_score(model: dict, task_scores: dict, weights: dict) -> float:
    """Weighted sum of capability × task-need × dimension-weight."""
    score = 0.0
    caps = model.get("capabilities", {})
    for dim in DIMENSIONS:
        cap = caps.get(dim, 0)
        need = task_scores.get(dim, 0)
        weight = weights.get(dim, 1.0)
        score += cap * need * weight
    return score


def passes_hard_constraints(model: dict, task: dict, constraints: dict) -> tuple[bool, str | None]:
    """Returns (ok, reason_if_blocked)."""
    # Pull privacy score from task.scores (consistent location)
    task_scores = task.get("scores", {})
    privacy_score = task_scores.get("privacy_locality", 0)

    # Privacy: if task needs local-only (privacy_locality >= 3), block remote
    if constraints.get("block_remote_when_local_required", True):
        if privacy_score >= 3 and model.get("availability") != "local":
            return False, "privacy_locality requires local model"

    # Cost ceiling: rough estimate using task input size if provided
    max_cost = constraints.get("max_cost_per_task_usd")
    if max_cost is not None and "estimated_input_tokens" in task:
        cost_in = model["cost_per_1k_tokens"]["input"] * (task["estimated_input_tokens"] / 1000)
        est_output = task.get("estimated_output_tokens", 1000)
        cost_out = model["cost_per_1k_tokens"]["output"] * (est_output / 1000)
        if cost_in + cost_out > max_cost:
            return False, f"est cost ${cost_in+cost_out:.4f} > max ${max_cost}"

    # Latency
    max_lat = constraints.get("max_latency_seconds")
    if max_lat is not None and model.get("avg_latency_seconds", 999) > max_lat:
        return False, f"latency {model['avg_latency_seconds']}s > max {max_lat}s"

    # Context size
    if "estimated_input_tokens" in task:
        if task["estimated_input_tokens"] > model.get("max_context_tokens", 0):
            return False, f"context {task['estimated_input_tokens']} > model max {model['max_context_tokens']}"

    return True, None


def apply_tie_breakers(a: dict, b: dict, breakers: list[str]) -> int:
    """Returns -1 if a wins, +1 if b wins, 0 if still tied."""
    for breaker in breakers:
        if breaker == "prefer_cheaper":
            cost_a = a["cost_per_1k_tokens"]["input"] + a["cost_per_1k_tokens"]["output"]
            cost_b = b["cost_per_1k_tokens"]["input"] + b["cost_per_1k_tokens"]["output"]
            if cost_a < cost_b:
                return -1
            if cost_b < cost_a:
                return 1
        elif breaker == "prefer_local":
            local_score = {"local": 2, "hybrid": 1, "cloud": 0}
            la = local_score.get(a.get("availability"), 0)
            lb = local_score.get(b.get("availability"), 0)
            if la > lb:
                return -1
            if lb > la:
                return 1
        elif breaker == "prefer_lower_latency":
            lat_a = a.get("avg_latency_seconds", 999)
            lat_b = b.get("avg_latency_seconds", 999)
            if lat_a < lat_b:
                return -1
            if lat_b < lat_a:
                return 1
    return 0


# ─── Main router ─────────────────────────────────────────────────────────────

def route(task: dict, config: dict | None = None) -> dict:
    """
    Pick the best model for `task`.

    task: {
        scores: dict of 14-dim scores (0-3 each),
        estimated_input_tokens: int (optional),
        estimated_output_tokens: int (optional),
        privacy_locality: int (0-3, optional, already in scores),
    }

    Returns: {model, score, ranked_alternatives, blocked_models}
    """
    cfg = config or load_config()
    weights = cfg.get("dimension_weights", {})
    constraints = cfg.get("hard_constraints", {})
    breakers = cfg.get("tie_breakers", [])
    models = cfg.get("models", [])

    task_scores = task.get("scores", {})

    ranked: list[tuple[float, dict]] = []
    blocked: list[tuple[dict, str]] = []

    for model in models:
        ok, reason = passes_hard_constraints(model, task, constraints)
        if not ok:
            blocked.append((model, reason))
            continue
        score = compute_model_score(model, task_scores, weights)
        ranked.append((score, model))

    # Sort: highest score first, then apply tie-breakers pairwise
    def sort_key(item):
        return item[0]

    # We sort with stable sort then resolve ties manually
    ranked.sort(key=sort_key, reverse=True)

    # Resolve ties at the top
    if len(ranked) >= 2:
        for i in range(len(ranked) - 1):
            a_score, a_model = ranked[i]
            b_score, b_model = ranked[i + 1]
            # Within 5% = "tied"
            if b_score > 0 and (a_score - b_score) / max(a_score, 1) < 0.05:
                tb = apply_tie_breakers(a_model, b_model, breakers)
                if tb > 0:
                    ranked[i], ranked[i + 1] = ranked[i + 1], ranked[i]

    return {
        "winner": ranked[0][1] if ranked else None,
        "winner_score": ranked[0][0] if ranked else 0,
        "ranked": [{"model": m["id"], "tier": m["tier"], "score": round(s, 2)} for s, m in ranked[:5]],
        "blocked": [{"model": m["id"], "reason": r} for m, r in blocked],
    }


# ─── CLI ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="NEO delegation scoring router")
    parser.add_argument("--task-preset", help="Name of a task preset in config.yaml")
    parser.add_argument("--scores", help="JSON dict of 14-dim scores (0-3)")
    parser.add_argument("--estimated-input-tokens", type=int, default=0)
    parser.add_argument("--estimated-output-tokens", type=int, default=1000)
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--explain", action="store_true", help="Show full scoring breakdown")
    parser.add_argument("--list-models", action="store_true")
    parser.add_argument("--list-presets", action="store_true")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be picked without returning a winner")
    args = parser.parse_args()

    cfg = load_config(args.config)

    if args.list_models:
        print(f"{'ID':<48} {'Tier':<5} {'Local':<6} {'$/1k in':<8} {'Ctx':<8} {'Lat':<5}")
        print("-" * 90)
        for m in cfg.get("models", []):
            print(f"{m['id']:<48} {m['tier']:<5} {m['availability']:<6} "
                  f"{m['cost_per_1k_tokens']['input']:<8} {m['max_context_tokens']:<8} "
                  f"{m['avg_latency_seconds']:<5}")
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
            print(f"ERROR: preset '{args.task_preset}' not found in config.", file=sys.stderr)
            print(f"Available: {list(cfg.get('task_presets', {}).keys())}", file=sys.stderr)
            sys.exit(1)
        scores = preset
    else:
        scores = json.loads(args.scores)

    task = {"scores": scores}
    if args.estimated_input_tokens:
        task["estimated_input_tokens"] = args.estimated_input_tokens
    if args.estimated_output_tokens:
        task["estimated_output_tokens"] = args.estimated_output_tokens

    if args.dry_run:
        # Cheap models first — sanity check
        result = route(task, cfg)
        if result["winner"]:
            print(f"[dry-run] Would route to: {result['winner']['id']} (score {result['winner_score']:.1f})")
        else:
            print("[dry-run] No model passed hard constraints.")
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