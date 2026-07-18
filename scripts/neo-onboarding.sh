#!/usr/bin/env bash
# ============================================================
# NEO Onboarding Wizard (v0.5 — assistant name in final output, root SOUL.md)
# ============================================================
# Designed to run automatically after neo-install.sh completes.
# Walks a new user through 6 personality questions, writes
# SOUL.md / USER.md / MEMORY.md, and (optionally) wires up
# a smarter cloud model or Telegram at the end.
#
# The first version of this script clobbered a real user's
# MEMORY.md when tested with `echo "" | bash`. The five
# defensive layers below are mandatory — don't remove them.
#
# Usage:
#   bash neo-onboarding.sh                  # full wizard (default: interactive)
#   bash neo-onboarding.sh --dry-run        # show what would be written, write nothing
#   bash neo-onboarding.sh --reset          # ignore existing files, force re-onboard
#   bash neo-onboarding.sh --noninteractive # for automation/testing
#                                           # (refuses to clobber real ~/.hermes data)
#   bash neo-onboarding.sh --skip-optional  # don't offer cloud model / Telegram at the end
#
# Exit codes:
#   0  success
#   1  user cancelled
#   2  dependency missing (hermes CLI not on PATH)
#   3  write failed
#   5  refused to run (e.g. --noninteractive against real data)
#
# !!! PITFALL: stdin-EOF clobber (2026-07-16) !!!
# Earlier version accepted empty stdin (`echo "" | bash …`) and overwrote
# the user's real SOUL.md / USER.md / MEMORY.md with all-blank values.
# Safeguards: (1) refuse --noninteractive when MEMORY.md already has real
# content, (2) always back up before overwriting, (3) cap required-field
# loops at 3 attempts with a placeholder fallback. Don't remove any of
# these. -- Will
# ============================================================

set -euo pipefail

# ---------- Defaults & flags ----------
DRY_RUN=false
FORCE_RESET=false
SKIP_OPTIONAL=false
NONINTERACTIVE=false
# Default assistant name. Set early so the idempotency message (which runs
# before the question) has a sensible name. Question 1/7 may overwrite this.
ASSISTANT_NAME="NEO"

for arg in "$@"; do
  case "$arg" in
    --dry-run)        DRY_RUN=true ;;
    --reset)          FORCE_RESET=true ;;
    --skip-optional)  SKIP_OPTIONAL=true ;;
    --noninteractive) NONINTERACTIVE=true ;;
    -h|--help)
      sed -n '2,30p' "$0"
      exit 0 ;;
    *)
      echo "Unknown flag: $arg" >&2
      exit 1 ;;
  esac
done

# ---------- Paths ----------
# 1. Respect HERMES_HOME override (used for sandboxed testing).
# 2. Ask Hermes itself where its config lives (works on every platform).
# 3. Fall back to platform-specific defaults for Windows-native bash.
# 4. Last resort: POSIX default ~/.hermes.
if [[ -z "${HERMES_HOME:-}" ]]; then
  if command -v hermes >/dev/null 2>&1; then
    _hermes_config_path="$(hermes config path 2>/dev/null || true)"
    if [[ -n "$_hermes_config_path" && -f "$_hermes_config_path" ]]; then
      # hermes config path returns the FILE; we want the directory
      HERMES_HOME="$(cd "$(dirname "$_hermes_config_path")" 2>/dev/null && pwd || true)"
    fi
  fi
  if [[ -z "${HERMES_HOME:-}" ]]; then
    # Platform-specific fallbacks
    if [[ -n "${LOCALAPPDATA:-}" ]]; then
      # Native Windows bash (Git Bash, MSYS2, Cygwin). $HOME is the Windows user dir.
      HERMES_HOME="$LOCALAPPDATA/hermes"
    elif [[ -n "${APPDATA:-}" && -z "${MSYS_NO_PATHCONV:-}" ]]; then
      # Older Windows bash without LOCALAPPDATA (rare)
      HERMES_HOME="$APPDATA/../LocalAppData/hermes"
    elif [[ -r /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL — Linux bash, but Windows files live under /mnt/c
      # USER is the WSL username; the Windows username usually matches
      _win_user="${USER:-${USERNAME:-}}"
      if [[ -n "$_win_user" && -d "/mnt/c/Users/$_win_user/AppData/Local/hermes" ]]; then
        HERMES_HOME="/mnt/c/Users/$_win_user/AppData/Local/hermes"
      fi
    fi
  fi
  if [[ -z "${HERMES_HOME:-}" ]]; then
    # POSIX default (Linux, macOS, WSL without matching Windows user dir)
    HERMES_HOME="$HOME/.hermes"
  fi
fi
# Convert Windows-style backslash paths to forward slashes (Git Bash etc.)
HERMES_HOME="${HERMES_HOME//\\//}"
# SOUL.md lives at HERMES_HOME/SOUL.md (the root), NOT in personas/.
# Hermes loads it via get_hermes_home() / "SOUL.md" (see
# hermes-agent/agent/prompt_builder.py:1841). The personas/ dir was wrong.
SOUL_FILE="$HERMES_HOME/SOUL.md"
PERSONAS_DIR="$HERMES_HOME/personas"  # kept for backward compat (unused)
MEMORIES_DIR="$HERMES_HOME/memories"
ENV_FILE="$HERMES_HOME/.env"
USER_FILE="$MEMORIES_DIR/USER.md"
MEMORY_FILE="$MEMORIES_DIR/MEMORY.md"
ONBOARDED_FLAG="$HERMES_HOME/.onboarded"
CONFIG_FILE="$HERMES_HOME/config.yaml"

# ---------- Color helpers (TTY only) ----------
if [[ -t 1 ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'; BLU=$'\033[34m'
  YLW=$'\033[33m'; RED=$'\033[31m'; NC=$'\033[0m'
else
  BOLD=""; DIM=""; GRN=""; BLU=""; YLW=""; RED=""; NC=""
fi

say()    { printf "%b\n" "$*"; }
header() { printf "\n%b== %s ==%b\n" "$BOLD$BLU" "$*" "$NC"; }
ok()     { printf "%b✓%b %s\n" "$GRN" "$NC" "$*"; }
warn()   { printf "%b!%b %s\n" "$YLW" "$NC" "$*" >&2; }
die()    { printf "%b✗%b %s\n" "$RED" "$NC" "$*" >&2; exit "${2:-1}"; }

trap 'printf "\n"; warn "Onboarding cancelled — your files were NOT modified."; exit 1' INT TERM

# ---------- Helpers ----------
prompt() {
  # prompt "Label" "default" → echoes value to stdout, sets REPLY
  local label="$1" default="${2:-}" reply
  if [[ -n "$default" ]]; then
    read -r -p "$(printf '%s%s%s [%s]: ' "$BOLD" "$label" "$NC" "$default")" reply || true
    REPLY="${reply:-$default}"
  else
    read -r -p "$(printf '%s%s%s: ' "$BOLD" "$label" "$NC")" reply || true
    REPLY="${reply:-}"
  fi
}

yes_no() {
  # yes_no "Question?" → echoes "y" or "n", sets REPLY
  local question="$1" reply
  read -r -p "$(printf '%s%s%s (y/N): ' "$BOLD" "$question" "$NC")" reply || true
  case "${reply,,}" in
    y|yes) REPLY="y" ;;
    *)     REPLY="n" ;;
  esac
}

# ---------- Dependency check ----------
command -v hermes >/dev/null 2>&1 || die "hermes CLI not found on PATH. Install Hermes Agent first: https://hermes-agent.nousresearch.com/docs/getting-started" 2

# ---------- Safety: --noninteractive + existing real data = refuse ----------
# Refuse to clobber real data regardless of platform. We check whether the
# resolved HERMES_HOME looks like a "default" location (not an explicit
# HERMES_HOME override) AND MEMORY.md has content.
if [[ "$NONINTERACTIVE" == "true" && "$FORCE_RESET" != "true" && "$DRY_RUN" != "true" ]]; then
  # Build a list of "default" locations that count as real data (not test sandboxes)
  _is_default=false
  case "$HERMES_HOME" in
    "$HOME/.hermes"|"/root/.hermes")                  _is_default=true ;;  # Linux/macOS default
    "${LOCALAPPDATA:-}/hermes"|"${APPDATA:-}/../LocalAppData/hermes")  _is_default=true ;;  # Windows Git Bash / MSYS2
    "/mnt/c/Users"/*"/AppData/Local/hermes")          _is_default=true ;;  # WSL
  esac
  if [[ "$_is_default" == "true" && -s "$MEMORY_FILE" ]]; then
    die "Refusing to run in --noninteractive mode against real Hermes config with existing MEMORY.md.
This protects you from accidentally clobbering your live memory.
  ${BOLD}HERMES_HOME${NC} = $HERMES_HOME
Either:
  • run interactively (drop the --noninteractive flag), OR
  • use HERMES_HOME=/tmp/test-folder bash $0 --noninteractive for sandboxed testing, OR
  • pass --reset to explicitly confirm overwrite" 5
  fi
fi

# ---------- Idempotency check ----------
if [[ -f "$ONBOARDED_FLAG" && "$FORCE_RESET" != "true" && "$DRY_RUN" != "true" ]]; then
  say "${YLW}Heads up:${NC} $ASSISTANT_NAME has already been onboarded on this machine."
  say "Files written: ${DIM}$(date -r "$ONBOARDED_FLAG" '+%Y-%m-%d %H:%M:%S')${NC}"
  if [[ -t 0 ]]; then
    read -r -p "Re-onboard and overwrite SOUL/USER/MEMORY? (y/N): " REPLY
    [[ "$REPLY" =~ ^[Yy]$ ]] || { say "Nothing changed. Bye!"; exit 0; }
  else
    say "Non-interactive mode and --reset not set — exiting."
    say "Re-run with --reset to force."
    exit 0
  fi
fi

# ---------- Dry-run banner ----------
$DRY_RUN && say "${YLW}[DRY RUN]${NC} No files will be written, no .env changes, no network calls."

# ---------- Pre-flight: check local model availability ----------
# Local-only-first means we expect Ollama. If it's not there yet, we warn
# (don't block — wizard can still personalize their files for later).
header "Checking your local AI model"
LOCAL_MODEL_OK=false
if command -v ollama >/dev/null 2>&1; then
  if curl -s --max-time 3 http://localhost:11434/api/version >/dev/null 2>&1; then
    INSTALLED_MODEL="$(ollama list 2>/dev/null | awk 'NR>1{print $1; exit}')"
    if [[ -n "$INSTALLED_MODEL" ]]; then
      ok "Ollama running, model: ${BOLD}$INSTALLED_MODEL${NC}"
      LOCAL_MODEL_OK=true
    else
      warn "Ollama is installed but no model is pulled yet."
      say "  ${DIM}Run: ollama pull llama3.2${NC}"
    fi
  else
    warn "Ollama is installed but not running."
    say "  ${DIM}Start it with: ollama serve  (or open the Ollama app)${NC}"
  fi
else
  warn "Ollama not found. Your installer should have set this up."
  say "  ${DIM}Re-run neo-install.sh, or install from https://ollama.com/download${NC}"
fi

# ---------- Wizard intro ----------
header "Welcome to $ASSISTANT_NAME"
say "I'm going to ask 7 questions. Your answers shape how I work with you —"
say "how I talk, what I focus on, and what I always remember."
say ""
say "${DIM}Press Enter to accept the default shown in [brackets]. Ctrl-C to cancel anytime.${NC}"

# ---------- 7 questions ----------
# 1/7: what to call the assistant. This becomes the name the AI uses for itself
# in SOUL.md / USER.md / MEMORY.md. Default "NEO" (the product), but the user
# can rename it (e.g. "Jarvis", "Friday", "Rex"). Falls back to "NEO" on empty.
header "1/7  What would you like to call your AI assistant?"
prompt "Assistant name" "NEO"
ASSISTANT_NAME="$REPLY"
ASSISTANT_ATTEMPTS=0
while [[ -z "${ASSISTANT_NAME// /}" ]]; do
  ASSISTANT_ATTEMPTS=$((ASSISTANT_ATTEMPTS + 1))
  if (( ASSISTANT_ATTEMPTS >= 3 )); then
    warn "Using placeholder name 'NEO'. You can edit SOUL.md later."
    ASSISTANT_NAME="NEO"
    break
  fi
  warn "Please enter a name (or press Enter to accept the default 'NEO')."
  prompt "Assistant name" "NEO"
  ASSISTANT_NAME="$REPLY"
done

header "2/7  What should I call you?"
prompt "Your first name" ""
NAME="$REPLY"

# Required-field guard with cap (don't hang on empty stdin)
NAME_ATTEMPTS=0
while [[ -z "${NAME// /}" ]]; do
  NAME_ATTEMPTS=$((NAME_ATTEMPTS + 1))
  if (( NAME_ATTEMPTS >= 3 )); then
    warn "Using placeholder name. You can edit SOUL.md / USER.md later."
    NAME="friend"
    break
  fi
  warn "I need at least a first name to personalize your files. (Ctrl-C to cancel.)"
  prompt "Your first name" ""
  NAME="$REPLY"
done

header "3/7  What do you do?"
say "${DIM}One line. Engineer, founder, writer, pastor, student — whatever fits.${NC}"
prompt "Your role / identity" ""
ROLE="$REPLY"

header "4/7  What's the #1 thing you want to ship or figure out right now?"
say "${DIM}This becomes the north star I keep in mind when you ask me to do things.${NC}"
prompt "Primary goal" ""
GOAL="$REPLY"

header "5/7  How should I talk to you?"
say "${DIM}Examples: 'terse, no fluff' / 'warm and encouraging' / 'explain things like I'm 12' / 'match my energy'.${NC}"
prompt "Communication style" "terse, direct, no fluff"
STYLE="$REPLY"

header "6/7  What does success look like for you with $ASSISTANT_NAME?"
say "${DIM}What would make you say 'this was worth installing' in 30 days?${NC}"
prompt "Success looks like" ""
SUCCESS="$REPLY"

header "7/7  Anything I should ALWAYS remember about you?"
say "${DIM}Time zone, dietary needs, names of people you mention a lot, recurring constraints, things you hate.${NC}"
say "${DIM}(comma-separated, leave blank if nothing)${NC}"
prompt "Always remember" ""
REMEMBER="$REPLY"

# ---------- Summary ----------
header "Here's what I'll write"
say "  ${BOLD}Assistant${NC}    : $ASSISTANT_NAME"
say "  ${BOLD}Name${NC}        : $NAME"
say "  ${BOLD}Role${NC}        : $ROLE"
say "  ${BOLD}Goal${NC}        : $GOAL"
say "  ${BOLD}Style${NC}       : $STYLE"
say "  ${BOLD}Success${NC}     : $SUCCESS"
say "  ${BOLD}Remember${NC}    : ${REMEMBER:-<none>}"

if [[ -t 0 && "$NONINTERACTIVE" != "true" ]]; then
  read -r -p "$(printf '\n%bLook good?%b (Y/n): ' "$BOLD" "$NC")" CONFIRM
  [[ -z "$CONFIRM" || "$CONFIRM" =~ ^[Yy]$ ]] || { say "Cancelled."; exit 1; }
fi

# ---------- Build file contents ----------
NOW="$(date '+%Y-%m-%d %H:%M:%S %Z')"
GOAL_LINE="${GOAL:-<not set yet — fill in later>}"

SOUL_CONTENT="# $ASSISTANT_NAME Persona — $NAME
<!-- Generated by neo-onboarding.sh on $NOW -->
<!-- Edit this file any time to change how $ASSISTANT_NAME talks to you. -->

You are $ASSISTANT_NAME, $NAME's AI operator.

## Who $NAME is
- **Role:** $ROLE
- **Primary goal:** $GOAL_LINE
- **Definition of success:** ${SUCCESS:-<not set yet>}

## How to talk to $NAME
$STYLE
- Be concise. One offer at the end, not five.
- Never fabricate personal details — if you don't know, ask.
- If $NAME signals confusion (\"what do you mean?\"), drop to plain English — no jargon.
- When intent is ambiguous (\"test it\", \"update X\"), ASK before acting.
- Refer to yourself as \"$ASSISTANT_NAME\" when introducing yourself, not as \"an AI\" or \"an assistant\".

## Always remember about $NAME
${REMEMBER:-<!-- add standing facts here as you learn them -->}
"

USER_CONTENT="# $NAME — User Profile
<!-- Generated by neo-onboarding.sh on $NOW -->

**AI assistant name:** $ASSISTANT_NAME
**Name:** $NAME
**Role:** $ROLE
**Primary goal:** $GOAL_LINE
**Communication style:** $STYLE
**Success in 30 days:** ${SUCCESS:-<not set yet>}

**Standing facts:**
${REMEMBER:+- $REMEMBER}
"

# Memory budget: 2,200 chars total. Keep it well under to leave headroom.
MEMORY_CONTENT="**$NAME's AI assistant is named $ASSISTANT_NAME (role: ${ROLE:-TBD}):** Primary goal: $GOAL_LINE. Style: $STYLE. Success: ${SUCCESS:-<TBD>}.
§
**Always remember about $NAME:** ${REMEMBER:-<none yet>}.
§
**$NAME's product philosophy:** Value-first. No artificial limits, no monetization baggage. Anti-bottleneck: agents do the work, $NAME handles decisions.
"

# Truncate memory if it would blow budget (defensive)
if (( ${#MEMORY_CONTENT} > 1900 )); then
  warn "MEMORY.md would be ${#MEMORY_CONTENT} chars — trimming to 1900."
  MEMORY_CONTENT="${MEMORY_CONTENT:0:1880}…"
fi

# ---------- Write files ----------
# SOUL.md goes in HERMES_HOME root (no subdir needed).
# USER.md and MEMORY.md go in HERMES_HOME/memories/.
$DRY_RUN || mkdir -p "$MEMORIES_DIR"

write_file() {
  local path="$1" content="$2" label="$3"
  if $DRY_RUN; then
    say "${DIM}-- would write $label (${#content} chars) to $path --${NC}"
    return 0
  fi
  # ALWAYS back up before overwriting an existing file. Even with --reset.
  if [[ -f "$path" ]]; then
    local bak="${path}.bak.$(date +%s)"
    if cp "$path" "$bak" 2>/dev/null; then
      say "${DIM}  (backed up to $bak)${NC}"
    fi
  fi
  if printf '%s\n' "$content" > "$path"; then
    ok "wrote $label → $path"
  else
    die "failed to write $path" 3
  fi
}

header "Writing your files"
write_file "$SOUL_FILE"   "$SOUL_CONTENT"   "SOUL.md"
write_file "$USER_FILE"   "$USER_CONTENT"   "USER.md"
write_file "$MEMORY_FILE" "$MEMORY_CONTENT" "MEMORY.md"
$DRY_RUN || date -Iseconds > "$ONBOARDED_FLAG"

# ---------- Optional: smarter cloud model ----------

# ---------- Auto-fix: disable kawaii personality + reasoning_effort ----------
# Hermes ships with defaults that silently override what the wizard just
# wrote. Patch them here so the user never has to. (They were the #1
# gotcha in the original install guide — see the lead magnet's "Why this
# matters" section for the educational version.)
if [[ "$DRY_RUN" != "true" && -f "$CONFIG_FILE" ]]; then
  _patched=0
  if grep -q '^personality: kawaii' "$CONFIG_FILE" 2>/dev/null; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)" 2>/dev/null || true
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^personality: kawaii$|personality: ''|" "$CONFIG_FILE"
    else
      sed -i "s|^personality: kawaii$|personality: ''|" "$CONFIG_FILE"
    fi
    _patched=1
  fi
  if grep -q '^reasoning_effort: medium' "$CONFIG_FILE" 2>/dev/null; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak.$(date +%s)" 2>/dev/null || true
    if [[ "$(uname)" == "Darwin" ]]; then
      sed -i '' "s|^reasoning_effort: medium$|reasoning_effort: ''|" "$CONFIG_FILE"
    else
      sed -i "s|^reasoning_effort: medium$|reasoning_effort: ''|" "$CONFIG_FILE"
    fi
    _patched=1
  fi
  if [[ "$_patched" == "1" ]]; then
    say ""
    ok "Patched Hermes defaults that would override your persona (kawaii, reasoning_effort)"
  fi
fi

# Local Ollama is the default. Local is free and private but less capable.
# Offer a one-question upgrade path: pick a provider, paste a key, we verify.
# Gating: skip if user said --skip-optional. Otherwise run in BOTH interactive
# (-t 0) and noninteractive-piped modes — piped input is the only way to
# automate the cloud setup, and a real user with a real keyboard can always
# hit Ctrl-C to bail. Skip only when stdin is neither a TTY nor piped
# (i.e. closed from both ends, which would hang the read).
if [[ "$SKIP_OPTIONAL" != "true" ]]; then
  if [[ -t 0 ]]; then
    : # interactive — run normally
  elif [[ "$NONINTERACTIVE" == "true" ]]; then
    : # piped automation — run, will read from stdin
  else
    say "${DIM}Skipping cloud-model + Telegram prompts (stdin not interactive). Re-run without piping to set these up.${NC}"
    SKIP_OPTIONAL=true
  fi
fi

if [[ "$SKIP_OPTIONAL" != "true" ]]; then
  header "Optional: add a smarter model?"
  say "${DIM}Your local model (Ollama) is private and free, but smaller models can${NC}"
  say "${DIM}struggle with hard problems. You can add a cloud model as a backup —${NC}"
  say "${DIM}$ASSISTANT_NAME will use it for the hard stuff and fall back to local for quick chats.${NC}"
  say ""
  yes_no "Add a cloud model now? (you can do this later with 'hermes model')"
  if [[ "$REPLY" == "y" ]]; then
    # Pick provider
    say ""
    say "  ${BOLD}1)${NC} OpenAI (GPT-4o, GPT-4o-mini)  — best for general tasks"
    say "  ${BOLD}2)${NC} Anthropic (Claude Sonnet)    — best for long writing & reasoning"
    say "  ${BOLD}3)${NC} OpenRouter                   — access to all of the above + more"
    say "  ${BOLD}4)${NC} Skip for now"
    read -r -p "$(printf '%sPick one [1-4]%s: ' "$BOLD" "$NC")" PROVIDER_PICK
    case "$PROVIDER_PICK" in
      1) PROVIDER="openai";      KEY_VAR="OPENAI_API_KEY";    KEY_URL="https://platform.openai.com/api-keys" ;;
      2) PROVIDER="anthropic";   KEY_VAR="ANTHROPIC_API_KEY"; KEY_URL="https://console.anthropic.com/settings/keys" ;;
      3) PROVIDER="openrouter";  KEY_VAR="OPENROUTER_API_KEY";KEY_URL="https://openrouter.ai/keys" ;;
      *) PROVIDER="";            KEY_VAR="";                  KEY_URL="" ;;
    esac

    if [[ -n "$PROVIDER" ]]; then
      say ""
      say "${DIM}Get a key at: $KEY_URL${NC}"
      read -r -s -p "$(printf '%sPaste your %s key%s (input is hidden): ' "$BOLD" "$PROVIDER" "$NC")" API_KEY
      echo "" # newline after hidden input
      if [[ -z "${API_KEY// /}" ]]; then
        warn "Empty key — skipping. You can add it later with 'hermes model'."
      else
        # Write to .env (back up first)
        if $DRY_RUN; then
          say "${DIM}-- would append $KEY_VAR to $ENV_FILE --${NC}"
        else
          if [[ -f "$ENV_FILE" ]]; then
            cp "$ENV_FILE" "${ENV_FILE}.bak.$(date +%s)" 2>/dev/null || true
          fi
          # Remove existing key if present, then append
          if grep -q "^${KEY_VAR}=" "$ENV_FILE" 2>/dev/null; then
            sed -i.bak "/^${KEY_VAR}=/d" "$ENV_FILE" 2>/dev/null || true
          fi
          printf '\n%s=%s\n' "$KEY_VAR" "$API_KEY" >> "$ENV_FILE"
          chmod 600 "$ENV_FILE" 2>/dev/null || true
          ok "saved $KEY_VAR to $ENV_FILE"
        fi
      fi
    fi
  fi
fi

# ---------- Optional: Telegram (so NEO can message you) ----------
if [[ "$SKIP_OPTIONAL" != "true" ]]; then
  header "Optional: talk to $ASSISTANT_NAME from your phone?"
  say "${DIM}You can message $ASSISTANT_NAME from Telegram instead of always using the terminal.${NC}"
  say "${DIM}Setup takes ~5 min — instructions at:${NC}"
  say "${DIM}  https://hermes-agent.nousresearch.com/docs/user-guide/messaging/telegram${NC}"
  say ""
  yes_no "Set up Telegram now?"
  if [[ "$REPLY" == "y" ]]; then
    if $DRY_RUN; then
      say "${DIM}-- would run: hermes gateway setup telegram --non-interactive (guided walkthrough)${NC}"
    else
      hermes gateway setup || warn "Telegram setup didn't complete. You can run 'hermes gateway setup' later."
      ok "Telegram configured"
    fi
  else
    say "${DIM}Skipped. Run 'hermes gateway setup' anytime to add it later.${NC}"
  fi
fi

# ---------- Done ----------
header "You're set up"
say ""
say "${GRN}${BOLD}Welcome aboard, $NAME.${NC}"
say ""
say "Your files:"
say "  • ${DIM}$SOUL_FILE${NC}    (how $ASSISTANT_NAME behaves — edit anytime)"
say "  • ${DIM}$USER_FILE${NC}    (who you are — auto-loaded every session)"
say "  • ${DIM}$MEMORY_FILE${NC}  (durable facts — auto-loaded every session)"
say ""
say "Local AI status:"
if $LOCAL_MODEL_OK; then
  say "  ${GRN}✓${NC} Ollama is running with ${BOLD}$INSTALLED_MODEL${NC}"
else
  say "  ${YLW}!${NC} Local model not ready yet — see the warning above"
  say "    ${DIM}Run 'ollama serve' then 'ollama pull llama3.2' to fix.${NC}"
fi
say "  ${GRN}✓${NC} Patched Hermes defaults that would override your persona"
say ""
say "Try it now:"
say "  ${BOLD}hermes${NC}        # start chatting in your terminal"
say ""
say "Other commands:"
say "  ${BOLD}hermes model${NC}        # add/change AI model"
say "  ${BOLD}hermes skills list${NC}  # browse what $ASSISTANT_NAME can do"
say "  ${BOLD}hermes doctor${NC}       # check for any issues"
say ""
say "To re-run this wizard later: ${BOLD}bash ~/.hermes/scripts/neo-onboarding.sh --reset${NC}"
$DRY_RUN || echo "first-run complete: $NOW" >> "$ONBOARDED_FLAG"
exit 0
