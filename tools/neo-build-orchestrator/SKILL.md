---
name: neo-build-orchestrator
description: Use when Will asks NEO to build, create, develop, implement, scaffold, or ship any software artifact autonomously. Triggers on phrases like "build me", "create a", "develop", "make a", "set up", "wire up", "scaffold", "I want a", or any request to produce working code/files/projects from scratch. Routes through the 4-stage gate loop orchestrator (Plan -> Implement -> Troubleshoot -> Review) instead of ad-hoc coding.
version: 1.0.0
author: Will Oh / NEO
license: MIT
metadata:
  hermes:
    tags: [build, create, develop, scaffold, orchestrator, autonomous, gate-loop]
    related_skills: [dev-pipeline, plan, requesting-code-review, simplify-code, systematic-debugging]
---

# NEO Build Orchestrator

## Overview

When Will asks for any autonomous build task — a script, a tool, a service, a CLI, a scraper, a Notion integration, anything that produces working code — **route through the orchestrator script** instead of doing the work inline.

The orchestrator runs a 4-stage gate loop (Plan / Implement / Troubleshoot / Review) using Claude Code as the worker, with Telegram approval gates on critical operations (deploy, payments, outbound messaging, deletions, customer data access). State persists across sessions via `/tmp/neo_stage_N.json` so an interrupted build can resume.

**Do not write the code yourself.** Do not invent files inline. Do not produce a plan and stop. The orchestrator IS the pipeline.

## When to Use

**Load this skill when Will says any of:**

- "Build me a [X]"
- "Create a [tool/script/agent/integration]"
- "Develop [feature/system]"
- "Set up [infrastructure]"
- "Wire up [service A] to [service B]"
- "Scaffold [project]"
- "Make a [CLI/script/bot/dashboard]"
- "I need a [thing] that does [behavior]"
- "Ship me a [deliverable]"
- "Build [something] autonomously"

**Also load when:**

- The task implies multiple files / functions / components
- The task requires running tests or git operations
- Will says "make it work" or "get it running" or "ship it"
- The request is open-ended ("build a tool for X" vs "change line 42 of Y")

**Do NOT use for:**

- Single-line edits, typo fixes, or trivial tweaks
- Pure research / Q&A ("what is X?", "how does Y work?")
- Memory updates or skill authoring tasks
- Pure conversation or planning chat
- Tasks that explicitly should NOT spawn a worker (e.g. "just tell me how to do it")

## The command

```bash
python3 ~/.hermes/scripts/neo_orchestrator.py "<task description in Will's words>"
```

### Optional flags

```bash
# Dry-run mode — validates the gate loop without Telegram or Claude Code
python3 ~/.hermes/scripts/neo_orchestrator.py --dry-run "Build X"

# Resume an interrupted session
python3 ~/.hermes/scripts/neo_orchestrator.py --resume <session_id> "Continue from stage 2"

# Skip the planning stage (use only when Will has already given a precise spec)
python3 ~/.hermes/scripts/neo_orchestrator.py --skip-plan "Implement the exact spec in /tmp/spec.md"

# Restrict the worker to a specific directory (for sandboxing)
python3 ~/.hermes/scripts/neo_orchestrator.py --workdir ~/projects/x "Build a CLI in this dir"
```

## What the orchestrator does

### Stage 1 — Plan
Worker uses read-only tools (Read, Grep, Glob). Produces an implementation spec. Gate verdict options:
- `proceed` — spec is good, move to Stage 2
- `needs_human` — spec requires Will's input (unclear requirements)
- `halt` — task is infeasible or duplicates existing work

### Stage 2 — Implement
Worker uses Read, Edit, Write, Bash (pytest + git only). Writes code, runs tests, commits to git. Gate verdict:
- `proceed` — tests pass, move to Stage 3
- `needs_human` — blocked on external decision
- `halt` — implementation is unsound

### Stage 3 — Troubleshoot
Same tools as Stage 2. Up to 3 attempts to fix failing tests or git errors. Gate verdict:
- `proceed` — issues resolved
- `halt` — cannot resolve without human input

### Stage 4 — Review
Worker reads diff, runs git diff. Gate verdict:
- `proceed` — final delivery
- `halt` — review surfaced blocking issues

### Critical operation gating

If any stage marks `critical=true` (deploys, payments, outbound messaging, customer data, deletions), the orchestrator pauses and sends Will a Telegram approval request. Do not bypass this — Will needs the human gate.

## When you should NOT just defer to the orchestrator

Some tasks should be handled inline first, then escalated to the orchestrator if they grow:

1. **Quick exploration questions** — answer first, then ask "want me to build this?"
2. **Skill authoring** — use `skill_manage` directly, not the orchestrator
3. **Memory updates** — use `memory` tool directly
4. **Small edits to existing files** — use `patch` directly
5. **Cron job setup** — use `cronjob` tool directly

If Will's request is ambiguous ("should we do X?"), clarify first. The orchestrator is for execution, not deliberation.

## Common Pitfalls

1. **Building inline when Will said "build."** If the request involves producing new code/files/projects, ALWAYS route through the orchestrator. Even a "simple" 10-line script benefits from the gate loop because it catches Will-not-specified edge cases.

2. **Producing a plan and stopping.** NEO's instinct is to over-plan. The orchestrator handles planning internally. Your job is to fire the orchestrator and let it report back.

3. **Skipping the workdir flag for new projects.** If Will says "build me X" without a path, default the workdir to `~/projects/<sanitized-task-name>/` so the orchestrator doesn't pollute the cwd.

4. **Bypassing Telegram approval gates.** If the orchestrator surfaces a `critical=true` gate and Will says "just do it," confirm explicitly. The gate exists because the operation is irreversible or external-facing.

5. **Running orchestrator twice on the same task.** The orchestrator maintains state in `/tmp/neo_stage_N.json`. A second invocation can stomp the first. If you must restart, use `--resume <session_id>` with the existing SID.

6. **Using --dry-run for actual delivery.** Dry-run validates the gate loop but does NOT call Claude Code or send Telegram. Use it for testing the script itself, not for shipping work.

7. **Forgetting to verify the final deliverable.** After the orchestrator reports `proceed` on Stage 4, verify the artifact actually exists (`ls`, `git log`, run the code once). The orchestrator is honest but you are the last-mile verifier.

8. **Ignoring --skip-plan when Will gave a precise spec.** If Will says "implement exactly this spec from /tmp/spec.md," use `--skip-plan` to avoid the orchestrator rewriting the spec. Saves 5-10 minutes per build.

## Verification Checklist

Before reporting back to Will, verify:

- [ ] Orchestrator exit was clean (no Traceback, no `[CRITICAL]` blocks)
- [ ] Final gate was `proceed` (not `halt` or `needs_human`)
- [ ] Files exist at the expected paths (`ls`, `find`)
- [ ] Git commit was created (`git log -1`)
- [ ] Tests pass if applicable (`pytest` or equivalent)
- [ ] If critical gate fired, Will's Telegram approval was received BEFORE proceeding
- [ ] You told Will what was built, where it lives, and how to run it

## One-Shot Recipes

### Recipe 1: Will says "build me a [thing]"
```bash
# Sanitize task name for workdir
TASK_SLUG=$(echo "<will's request>" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | head -c 40)
mkdir -p ~/projects/$TASK_SLUG
python3 ~/.hermes/scripts/neo_orchestrator.py --workdir ~/projects/$TASK_SLUG "<will's verbatim request>"
```

### Recipe 2: Will provides a spec and says "implement this"
```bash
python3 ~/.hermes/scripts/neo_orchestrator.py --skip-plan "Implement the spec at /tmp/spec.md. Repo: <path>. Branch: feature/<slug>."
```

### Recipe 3: Will says "fix this broken thing" (debug-only)
```bash
# Bug fixes are also builds. Route through orchestrator.
python3 ~/.hermes/scripts/neo_orchestrator.py "Fix: <error message>. Repo: <path>. File: <path>. Expected: <behavior>. Actual: <behavior>."
```

### Recipe 4: Resume after interruption
```bash
ls /tmp/neo_stage_*.json 2>/dev/null  # find the SID
python3 ~/.hermes/scripts/neo_orchestrator.py --resume <sid> "Continue from where we left off"
```

### Recipe 5: Test the orchestrator itself (no Claude Code call)
```bash
python3 ~/.hermes/scripts/neo_orchestrator.py --dry-run "Sanity check the gate loop"
```
