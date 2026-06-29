#!/bin/bash
set -e

# =============================================================================
# NEO Lite Entrypoint — First-run wizard + License enforcement + Hermes Gateway
# =============================================================================

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
echo "║               ~ Free Tier ~                  ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ─── License key validation ─────────────────────────────────────────────────
# Supported env vars:
#   NEO_LICENSE_KEY    — License key (e.g., NEO-FREE-XXXX, NEO-MASTER-XXXX)
#   NEO_DAILY_LIMIT    — Custom daily conversation limit (default: 5)
#
# Key types:
#   NEO-FREE-XXXX      — Free tier with daily cap (default 5)
#   NEO-MASTER-XXXX    — Unlimited conversations. For affiliates/influencers.
#   NEO-EVAL-XXXX      — Evaluation: 14-day unlimited (no telemetry needed)

LICENSE_FILE="${HERMES_HOME}/.license"
DAILY_LIMIT="${NEO_DAILY_LIMIT:-5}"
LICENSE_TYPE="free"

if [ -n "$NEO_LICENSE_KEY" ]; then
    echo "$NEO_LICENSE_KEY" > "$LICENSE_FILE"
    echo -e "${GREEN}✓ License key loaded from environment${NC}"
fi

if [ -f "$LICENSE_FILE" ]; then
    KEY=$(cat "$LICENSE_FILE")
    PREFIX="${KEY%%-*}"

    case "$PREFIX" in
        NEO-FREE)
            DAILY_LIMIT="${NEO_DAILY_LIMIT:-5}"
            LICENSE_TYPE="free"
            echo -e "${CYAN}🔑 NEO Free — ${DAILY_LIMIT} conversations/day${NC}"
            ;;
        NEO-MASTER)
            DAILY_LIMIT=999999
            LICENSE_TYPE="master"
            echo -e "${GREEN}👑 NEO Master Key activated — unlimited conversations${NC}"
            ;;
        NEO-EVAL)
            DAILY_LIMIT=999999
            LICENSE_TYPE="eval"
            echo -e "${CYAN}🔬 NEO Evaluation — unlimited for 14 days${NC}"
            ;;
        *)
            echo -e "${YELLOW}⚠ Unknown license key format. Defaulting to free tier.${NC}"
            DAILY_LIMIT="${NEO_DAILY_LIMIT:-5}"
            ;;
    esac
fi

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

    # Save user profile
    cat > "${HERMES_HOME}/user_profile.json" << EOF
{
  "name": "${USER_NAME}",
  "email": "${USER_EMAIL}",
  "role": "${USER_ROLE}",
  "tech_level": ${TECH_LEVEL},
  "goal": "${USER_GOAL}",
  "onboarded_at": "$(date -Iseconds)"
}
EOF

    # Generate SOUL.md
    cat > "${HERMES_HOME}/SOUL.md" << EOF
# My NEO Story

**Name:** ${USER_NAME}
**Role:** ${USER_ROLE}
**Tech Level:** ${TECH_LEVEL}
**Goal:** ${USER_GOAL}

This is the beginning of my journey with NEO — an AI Chief of Staff
that learns who I am, remembers what matters, and helps me move faster.
EOF

    echo ""
    echo -e "${GREEN}✓ Great! Nice to meet you, ${USER_NAME}!${NC}"
    echo ""

    # Track license key alongside onboarding
    [ -f "$LICENSE_FILE" ] && cp "$LICENSE_FILE" "${HERMES_HOME}/.license"

    # Daily conversation counter
    echo "0" > "${HERMES_HOME}/.daily_count"
    echo "$(date +%Y-%m-%d)" > "${HERMES_HOME}/.daily_date"

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

    cat > "${HERMES_HOME}/user_profile.json" << EOF
{
  "name": "${USER_NAME}",
  "email": "${USER_EMAIL}",
  "role": "${USER_ROLE}",
  "tech_level": ${TECH_LEVEL},
  "goal": "${USER_GOAL}",
  "onboarded_at": "$(date -Iseconds)",
  "wizard_skipped": true
}
EOF

    cat > "${HERMES_HOME}/SOUL.md" << EOF
# My NEO Story

**Name:** ${USER_NAME}
**Role:** ${USER_ROLE}
**Tech Level:** ${TECH_LEVEL}
**Goal:** ${USER_GOAL}

This is the beginning of my journey with NEO — an AI Chief of Staff
that learns who I am, remembers what matters, and helps me move faster.

> The interactive wizard was skipped (no TTY / NEO_NONINTERACTIVE=1).
> Re-run from a terminal: \`docker compose exec neo-lite bash /entrypoint.sh\`
> Or update these fields in NEO via Telegram: "set my name to Will".
EOF

    # License + counter
    [ -f "$LICENSE_FILE" ] && cp "$LICENSE_FILE" "${HERMES_HOME}/.license"
    echo "0" > "${HERMES_HOME}/.daily_count"
    echo "$(date +%Y-%m-%d)" > "${HERMES_HOME}/.daily_date"
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

# ─── Daily limit check ──────────────────────────────────────────────────────
TODAY=$(date +%Y-%m-%d)
SAVED_DATE=$(cat "${HERMES_HOME}/.daily_date" 2>/dev/null || echo "")

if [ "$TODAY" != "$SAVED_DATE" ]; then
    echo "0" > "${HERMES_HOME}/.daily_count"
    echo "$TODAY" > "${HERMES_HOME}/.daily_date"
fi

COUNT=$(cat "${HERMES_HOME}/.daily_count" 2>/dev/null || echo "0")
if [ "$COUNT" -ge "$DAILY_LIMIT" ] 2>/dev/null; then
    if [ "$LICENSE_TYPE" = "master" ] || [ "$LICENSE_TYPE" = "eval" ]; then
        # Master/eval keys bypass the counter
        :
    else
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}  ⏰ You've used ${COUNT} conversations today.${NC}"
        echo -e "${YELLOW}  Limit: ${DAILY_LIMIT}. Upgrade to continue.${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "NEO Lite Gateway running on http://localhost:8080"
        echo "The web UI will show your upgrade prompt."
        echo ""
        echo "Upgrade at: https://neocloud.ai/pricing"
        echo "Or set NEO_LICENSE_KEY env var to unlock."
        sleep infinity
    fi
fi

# Increment counter (skip for master/eval to avoid wrapping)
if [ "$LICENSE_TYPE" != "master" ] && [ "$LICENSE_TYPE" != "eval" ]; then
    echo $((COUNT + 1)) > "${HERMES_HOME}/.daily_count"
fi

# ─── Show status ────────────────────────────────────────────────────────────
REMAINING=$((DAILY_LIMIT - COUNT))
echo -e "${GREEN}✓ ${COUNT}/${DAILY_LIMIT} conversations used today${NC}"
echo ""

# ─── Start Hermes Gateway ───────────────────────────────────────────────────
echo -e "${GREEN}Starting NEO Lite Gateway...${NC}"
echo ""

# Run Hermes gateway in foreground
exec hermes gateway run 2>&1
