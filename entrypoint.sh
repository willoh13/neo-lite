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
if [ ! -f "${HERMES_HOME}/.onboarded" ]; then
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
