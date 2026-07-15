#!/bin/bash
set -e

# =============================================================================
# NEO Lite Entrypoint — First-run wizard + Hermes Gateway
# =============================================================================
# No rate limits. No license enforcement. Just help people.

HERMES_HOME="${HOME}/.hermes"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════╗"
echo "║           NEO Lite — AI Chief of Staff       ║"
echo "║              ~ Free, Open Source ~            ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# License + rate-limit system removed 2026-07-14.
# NEO Lite is free, open, no limits. White-glove setup is the offer, not enforcement.
# See docs/services.md (white-glove install) and docs/pricing.md (future Pro Skills Bundle).

# ─── First-run wizard ──────────────────────────────────────────────────────
# Skip wizard if: no TTY (detached docker compose up -d), NEO_NONINTERACTIVE=1,
# or env vars NEO_USER_NAME / NEO_USER_EMAIL / NEO_USER_ROLE provided.
SKIP_WIZARD=0
if [ ! -t 0 ]; then SKIP_WIZARD=1; echo -e "${YELLOW}⚠ No TTY detected — running in non-interactive mode.${NC}"; fi
if [ -n "$NEO_NONINTERACTIVE" ]; then SKIP_WIZARD=1; echo -e "${YELLOW}⚠ NEO_NONINTERACTIVE=1 — skipping wizard.${NC}"; fi

if [ ! -f "${HERMES_HOME}/.onboarded" ] && [ "$SKIP_WIZARD" -eq 0 ]; then
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}  👋 Welcome! Let's get to know each other.${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Name
    read -p "What's your name? " USER_NAME
    while [ -z "$USER_NAME" ]; do
        read -p "Name can't be empty. What's your name? " USER_NAME
    done

    # Email capture (optional but encouraged)
    read -p "Email (optional — for upgrades & tips): " USER_EMAIL

    # Role
    read -p "What do you do? (e.g., Founder, Developer, Creator) " USER_ROLE
    [ -z "$USER_ROLE" ] && USER_ROLE="AI Enthusiast"

    # Top goal
    echo "What's your #1 goal right now? (Press Enter for default)"
    read -p "  > " USER_GOAL
    [ -z "$USER_GOAL" ] && USER_GOAL="Explore what an AI Chief of Staff can do"

    # Tech level
    echo ""
    echo "How technical are you?"
    echo "  1) Not very — I want things to just work"
    echo "  2) Somewhat — I can run a terminal command"
    echo "  3) Very — I build with Docker regularly"
    read -p "  (1-3): " TECH_LEVEL
    while [[ ! "$TECH_LEVEL" =~ ^[1-3]$ ]]; do
        read -p "  Please enter 1, 2, or 3: " TECH_LEVEL
    done

    # AI name (REQUIRED — this is how the user will address their agent)
    # This is NOT the user's name. This is the name of their AI.
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  🤖 Time to name your AI.${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Pick a name you'll actually say out loud in conversation."
    echo "(You'll be saying 'Hey <name>, remind me to...' all day.)"
    echo ""
    echo "Some ideas: Atlas, Friday, Nova, Jinx, Sage, Echo, Cal, Iris"
    echo "(Press Enter to use 'Assistant')"
    read -p "  AI name > " NEO_AI_NAME
    [ -z "$NEO_AI_NAME" ] && NEO_AI_NAME="Assistant"

    # AI tone (one-word voice preset)
    echo ""
    echo "What voice should ${NEO_AI_NAME} have?"
    echo "  1) casual    — friendly, warm, occasional humor (default)"
    echo "  2) formal    — measured, professional, no jokes"
    echo "  3) warm      — supportive, encouraging, asks how you're doing"
    echo "  4) terse     — minimal words, no fluff, just the answer"
    echo "  5) sarcastic — dry wit, calls you on your BS, fun"
    read -p "  (1-5): " TONE_CHOICE
    case "$TONE_CHOICE" in
        2) NEO_AI_TONE="formal" ;;
        3) NEO_AI_TONE="warm" ;;
        4) NEO_AI_TONE="terse" ;;
        5) NEO_AI_TONE="sarcastic" ;;
        *) NEO_AI_TONE="casual" ;;
    esac

    # Save user profile
    cat > "${HERMES_HOME}/user_profile.json" << EOF
{
  "name": "${USER_NAME}",
  "email": "${USER_EMAIL}",
  "role": "${USER_ROLE}",
  "tech_level": ${TECH_LEVEL},
  "goal": "${USER_GOAL}",
  "ai_name": "${NEO_AI_NAME}",
  "ai_tone": "${NEO_AI_TONE}",
  "onboarded_at": "$(date -Iseconds)"
}
EOF

    # Generate SOUL.md
    # This is the agent's identity (slot #1 in the system prompt).
    # Mixes: user facts (so the agent knows who they're helping) + agent identity + voice.
    cat > "${HERMES_HOME}/SOUL.md" << EOF
# ${NEO_AI_NAME}'s Identity

## Who I am

I am **${NEO_AI_NAME}**, a personal AI partner.

I am not "NEO" — that's Will's AI, the original. I am ${NEO_AI_NAME}, named
by my user. I introduce myself as ${NEO_AI_NAME} if asked.

I was created by the user installing NEO Lite. My purpose is to help them
move faster, remember what matters, and be a partner — not a tool.

## Who I help

|**Their name:** ${USER_NAME}
|**What they do:** ${USER_ROLE}
|**Tech level:** ${TECH_LEVEL}/3
|**Their goal right now:** ${USER_GOAL}

## How I speak

I speak in a **${NEO_AI_TONE}** voice. That means:
EOF

    # Append tone-specific guidance
    case "${NEO_AI_TONE}" in
        formal)
            cat >> "${HERMES_HOME}/SOUL.md" << EOF
- I am measured, professional, and precise
- I avoid jokes, slang, and casual asides
- I lead with the answer, then provide supporting detail
- I treat every interaction as if it might be quoted in a board meeting
EOF
            ;;
        warm)
            cat >> "${HERMES_HOME}/SOUL.md" << EOF
- I am supportive, encouraging, and patient
- I ask how they're doing before diving into tasks
- I celebrate wins and acknowledge frustrations
- I treat every conversation as a check-in with a friend
EOF
            ;;
        terse)
            cat >> "${HERMES_HOME}/SOUL.md" << EOF
- I use the minimum words needed to be useful
- I skip pleasantries, summaries, and recap phrases
- I do not explain what I'm about to do — I just do it
- If a one-word answer is correct, I give one word
EOF
            ;;
        sarcastic)
            cat >> "${HERMES_HOME}/SOUL.md" << EOF
- I have dry wit and call out bad ideas plainly
- I am fun, not mean — the goal is honesty with a smile
- I use sarcasm only when it serves the user; never to be cruel
- I do not soften truths to spare feelings
EOF
            ;;
        *)  # casual (default)
            cat >> "${HERMES_HOME}/SOUL.md" << EOF
- I am friendly, warm, and occasionally funny
- I talk like a smart friend, not a corporate assistant
- I use contractions, simple words, and short paragraphs
- I lead with the answer, then the why
EOF
            ;;
    esac

    cat >> "${HERMES_HOME}/SOUL.md" << EOF

## What I never do

- I never pretend to be a different AI
- I never use the name "NEO" to refer to myself
- I never make up facts, API endpoints, or file contents
- I never claim a task is "done" without verifying

## How to change me

Edit \`\${HERMES_HOME}/SOUL.md\` directly for lasting changes.
Edit \`/workspace/personality.md\` (if present) for session-only overrides.
Or change \`NEO_AI_NAME\` and \`NEO_AI_TONE\` in your \`.env\` and restart me.
EOF

    # Persist AI name + tone to .env so they survive container restarts
    if [ -f "${HERMES_HOME}/.env" ]; then
        # Update or append
        if grep -q "^NEO_AI_NAME=" "${HERMES_HOME}/.env"; then
            sed -i "s/^NEO_AI_NAME=.*/NEO_AI_NAME=${NEO_AI_NAME}/" "${HERMES_HOME}/.env"
        else
            echo "NEO_AI_NAME=${NEO_AI_NAME}" >> "${HERMES_HOME}/.env"
        fi
        if grep -q "^NEO_AI_TONE=" "${HERMES_HOME}/.env"; then
            sed -i "s/^NEO_AI_TONE=.*/NEO_AI_TONE=${NEO_AI_TONE}/" "${HERMES_HOME}/.env"
        else
            echo "NEO_AI_TONE=${NEO_AI_TONE}" >> "${HERMES_HOME}/.env"
        fi
    fi

    echo ""
    echo -e "${GREEN}✓ Great! Nice to meet you, ${USER_NAME}! Your AI is ${NEO_AI_NAME}.${NC}"
    echo ""

    # Mark onboarded
    date > "${HERMES_HOME}/.onboarded"
fi

# ─── Non-interactive first-run setup ─────────────────────────────────────────
# If wizard was skipped (no TTY / NEO_NONINTERACTIVE=1), still create a minimal
# profile so the gateway can boot and the user can re-run the wizard from
# Telegram or terminal later.
if [ ! -f "${HERMES_HOME}/.onboarded" ] && [ "$SKIP_WIZARD" -eq 1 ]; then
    USER_NAME="${NEO_USER_NAME:-Operator}"
    USER_EMAIL="${NEO_USER_EMAIL:-}"
    USER_ROLE="${NEO_USER_ROLE:-AI Enthusiast}"
    USER_GOAL="${NEO_USER_GOAL:-Explore what an AI Chief of Staff can do}"
    TECH_LEVEL="${NEO_TECH_LEVEL:-2}"
    NEO_AI_NAME="${NEO_AI_NAME:-Assistant}"
    NEO_AI_TONE="${NEO_AI_TONE:-casual}"

    cat > "${HERMES_HOME}/user_profile.json" << EOF
{
  "name": "${USER_NAME}",
  "email": "${USER_EMAIL}",
  "role": "${USER_ROLE}",
  "tech_level": ${TECH_LEVEL},
  "goal": "${USER_GOAL}",
  "ai_name": "${NEO_AI_NAME}",
  "ai_tone": "${NEO_AI_TONE}",
  "onboarded_at": "$(date -Iseconds)",
  "wizard_skipped": true
}
EOF

    cat > "${HERMES_HOME}/SOUL.md" << EOF
# ${NEO_AI_NAME}'s Identity

## Who I am

I am **${NEO_AI_NAME}**, a personal AI partner.

I was created by the user installing NEO Lite. I help ${USER_NAME} (a ${USER_ROLE}) move faster.

## How I speak

I speak in a **${NEO_AI_TONE}** voice. To change me, re-run the wizard:
\`docker compose exec neo-lite bash /entrypoint.sh\`

> The interactive wizard was skipped (no TTY / NEO_NONINTERACTIVE=1).
> Re-run from a terminal: \`docker compose exec neo-lite bash /entrypoint.sh\`
> Or set NEO_AI_NAME / NEO_AI_TONE in your \`.env\` and restart the container.
EOF

    date > "${HERMES_HOME}/.onboarded"

    echo ""
    echo -e "${GREEN}✓ Profile created (non-interactive). Edit via Telegram or re-run wizard.${NC}"
fi

# ─── Ollama model variants setup (first-run only) ───────────────────────────
# Create -direct variants of reasoning-mode models so they return content via
# the OpenAI-compat layer. Only runs when:
#   1. Ollama is reachable (OLLAMA_BASE_URL responds, or host.docker.internal)
#   2. We haven't done it before (marker file .ollama_variants_created)
# Skipped gracefully if Ollama isn't running — customer can run manually:
#   docker compose exec neo-lite python3 /root/.hermes/scripts/create_direct_variants.py
VARIANTS_MARKER="${HERMES_HOME}/.ollama_variants_created"
if [ ! -f "$VARIANTS_MARKER" ]; then
    OLLAMA_CHECK_URL="${OLLAMA_BASE_URL:-http://host.docker.internal:11434}"
    # Strip /v1 suffix for health check
    OLLAMA_HEALTH_URL="${OLLAMA_CHECK_URL%/v1}"

    if curl -s --max-time 3 "$OLLAMA_HEALTH_URL/api/tags" > /dev/null 2>&1; then
        echo ""
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}  🔧 Setting up Ollama model variants...${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

        if python3 /root/.hermes/scripts/create_direct_variants.py 2>&1 | tail -10; then
            date > "$VARIANTS_MARKER"
            echo -e "${GREEN}✓ Ollama variants ready${NC}"
        else
            echo -e "${YELLOW}⚠ Variant creation had errors. Run manually:${NC}"
            echo -e "${YELLOW}  docker compose exec neo-lite python3 /root/.hermes/scripts/create_direct_variants.py${NC}"
        fi
    else
        echo ""
        echo -e "${YELLOW}⚠ Ollama not reachable at ${OLLAMA_HEALTH_URL}${NC}"
        echo -e "${YELLOW}  Skipping variant setup. To enable reasoning models later:${NC}"
        echo -e "${YELLOW}  1. Start Ollama${NC}"
        echo -e "${YELLOW}  2. docker compose exec neo-lite python3 /root/.hermes/scripts/create_direct_variants.py${NC}"
        # Still mark as done so we don't spam this every restart
        date > "$VARIANTS_MARKER"
    fi
fi

# ─── Start Hermes Gateway ───────────────────────────────────────────────────
echo -e "${GREEN}Starting NEO Lite Gateway...${NC}"
echo ""

# Run Hermes gateway in foreground
exec hermes gateway run 2>&1
