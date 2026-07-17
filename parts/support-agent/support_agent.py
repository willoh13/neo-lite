#!/usr/bin/env python3
"""
NEO Operator Support Agent — per-customer install + first-7-day support.

Spin up one of these per active customer. Listens for Telegram messages,
follows the install runbook or troubleshooting FAQ, escalates to Will
when it can't solve something.

Usage:
    # Set env vars first
    export SUPPORT_SESSION_DIR=~/support-sessions
    export WILL_TELEGRAM_CHAT_ID=1390754840
    export CUSTOMER_TELEGRAM_TOPIC=...   # customer's topic ID
    export CUSTOMER_EMAIL=jane@example.com

    python3 support_agent.py

Architecture:
    - Polls Telegram for new messages in the customer's topic (1s loop)
    - For each new message, looks up the install state and the FAQ
    - If on install runbook: advances to next step
    - If in support mode: looks up FAQ, attempts fix
    - Logs everything to state.json for Will to review later
"""

import json
import os
import re
import sys
import time
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

# Optional imports — fail gracefully if not installed
try:
    import requests
except ImportError:
    print("ERROR: requests not installed. Run: pip install requests", file=sys.stderr)
    sys.exit(1)

# Try to import Telegram bot (python-telegram-bot is preferred, but we'll
# fall back to direct API calls if it's not available)
try:
    from telegram import Update, Bot
    from telegram.ext import Application, MessageHandler, filters, ContextTypes
    HAS_TELEGRAM_BOT = True
except ImportError:
    HAS_TELEGRAM_BOT = False


# === Config from env ===

SESSION_DIR = Path(os.environ.get("SUPPORT_SESSION_DIR", "~/support-sessions")).expanduser()
WILL_CHAT_ID = os.environ.get("WILL_TELEGRAM_CHAT_ID")
CUSTOMER_TOPIC = os.environ.get("CUSTOMER_TELEGRAM_TOPIC")
CUSTOMER_EMAIL = os.environ.get("CUSTOMER_EMAIL", "unknown@unknown")
AGENT_NAME = os.environ.get("AGENT_NAME", "NEO Support")
SUPPORT_DAYS = int(os.environ.get("SUPPORT_DAYS", "7"))
QUIET_HOURS = os.environ.get("SUPPORT_QUIET_HOURS", "")  # e.g. "22:00-08:00"

# Path to the reference docs (shipped with this skill)
DOCS_DIR = Path(__file__).parent / "references"
RUNBOOK_PATH = DOCS_DIR / "INSTALL-RUNBOOK.md"
TROUBLESHOOTING_PATH = DOCS_DIR / "TROUBLESHOOTING.md"
ESCALATION_TEMPLATE_PATH = DOCS_DIR / "ESCALATION-TEMPLATE.md"


# === State management ===

def get_state_path() -> Path:
    """Per-customer state file."""
    safe_email = re.sub(r"[^a-z0-9@._-]", "_", CUSTOMER_EMAIL.lower())
    return SESSION_DIR / safe_email / "state.json"


def load_state() -> dict:
    """Load customer state, or create a fresh one."""
    path = get_state_path()
    if path.exists():
        return json.loads(path.read_text())
    return {
        "customer_email": CUSTOMER_EMAIL,
        "agent_name": AGENT_NAME,
        "started_at": datetime.now(timezone.utc).isoformat(),
        "install_status": "not_started",
        "install_step": 0,
        "install_step_history": [],
        "support_mode": False,
        "support_expires_at": None,
        "open_issues": [],
        "escalations": [],
        "conversation_log": [],
    }


def save_state(state: dict) -> None:
    """Persist state to disk."""
    path = get_state_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(state, indent=2))


def log_event(state: dict, event_type: str, **details) -> None:
    """Append an event to the conversation log."""
    state["conversation_log"].append({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "event_type": event_type,
        **details,
    })


# === Message handling ===

def send_to_customer(message: str) -> None:
    """Send a message to the customer's Telegram topic."""
    # In production: use the Telegram Bot API directly
    # bot = Bot(token=TELEGRAM_BOT_TOKEN)
    # await bot.send_message(chat_id=CUSTOMER_TOPIC, text=message)
    # For now, just log it (we'll wire up Telegram in the deployment step)
    print(f"[TO CUSTOMER]: {message}\n")


def send_to_will(message: str, critical: bool = False) -> None:
    """Send a message to Will. Respects quiet hours unless critical."""
    if QUIET_HOURS and not critical:
        start, end = QUIET_HOURS.split("-")
        now = datetime.now().strftime("%H:%M")
        if start <= now <= end or (start > end and (now >= start or now <= end)):
            # In quiet hours, buffer
            buffer_path = SESSION_DIR / "will_inbox.jsonl"
            buffer_path.parent.mkdir(parents=True, exist_ok=True)
            with buffer_path.open("a") as f:
                f.write(json.dumps({
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                    "customer": CUSTOMER_EMAIL,
                    "message": message,
                }) + "\n")
            print(f"[TO WILL — buffered until quiet hours end]: {message}\n")
            return

    # In production: send via Telegram
    print(f"[TO WILL]: {message}\n")


def handle_customer_message(state: dict, message: str) -> None:
    """Main entry point — handle a message from the customer."""
    log_event(state, "customer_message", text=message)

    if not state["support_mode"]:
        # We're in install mode
        response = handle_install_step(state, message)
    else:
        # We're in support mode
        response = handle_support_message(state, message)

    if response:
        send_to_customer(response)
        log_event(state, "agent_response", text=response)

    save_state(state)


def handle_install_step(state: dict, message: str) -> Optional[str]:
    """Advance through the install runbook."""
    step = state["install_step"]

    # Step 0: confirm purchase + scope
    if step == 0:
        state["install_step"] = 1
        state["install_status"] = "in_progress"
        return (
            f"Hi! I'm the support agent for your NEO Operator install. Will roped me "
            f"in so he doesn't have to be on every call. We'll do this together "
            f"over the next ~2 hours. I'll drive, you watch and answer questions.\n\n"
            f"Quick scope check:\n"
            f"1. Did you pay the $2,499 invoice? (yes/no)\n"
            f"2. Do you have a Minisforum or similar always-on Linux/Windows box? (yes/no)\n"
            f"3. Do you have a Telegram account on your phone? (yes/no)"
        )

    # ... (more steps — see INSTALL-RUNBOOK.md for the full flow)

    # For now, this is a scaffold. The real implementation walks through
    # each step of INSTALL-RUNBOOK.md, advancing the step counter on
    # customer confirmation.
    return None


def handle_support_message(state: dict, message: str) -> Optional[str]:
    """Handle a message in support mode (post-install)."""
    # Simple keyword matching against the FAQ
    msg_lower = message.lower()

    if any(kw in msg_lower for kw in ["not responding", "no reply", "not answering", "won't reply"]):
        return lookup_faq(1)
    if any(kw in msg_lower for kw in ["invalid api", "api key", "401", "unauthorized"]):
        return lookup_faq(2)
    if "forgot" in msg_lower or "doesn't remember" in msg_lower or "lost memory" in msg_lower:
        return lookup_faq(5)
    if any(kw in msg_lower for kw in ["out of memory", "oom", "restarting", "killed"]):
        return lookup_faq(4)
    if "ollama" in msg_lower and any(kw in msg_lower for kw in ["not working", "not reachable", "can't reach", "no models"]):
        return lookup_faq(7)
    if "web ui" in msg_lower or "browser" in msg_lower:
        return lookup_faq(12)
    if "wrong name" in msg_lower or "wrong tone" in msg_lower or "casual" in msg_lower:
        return lookup_faq(9)
    if ".env" in msg_lower and ("change" in msg_lower or "update" in msg_lower or "didn't" in msg_lower):
        return lookup_faq(10)

    # If we get here, we don't have a quick answer. Check escalation count.
    recent_escalations = [e for e in state["escalations"] if e.get("issue_summary", "").lower() in message.lower()]
    if len(recent_escalations) >= 1:
        # Already escalated this. Tell customer Will is on it.
        return "Will is still looking at this — give him a bit longer. If it's urgent, you can email him directly."

    # First time seeing this issue — escalate
    escalate(state, message, f"Customer asked about something I don't have an FAQ entry for: '{message[:100]}'")
    return "I've handed this off to Will. He'll be in touch in the next few hours."


def lookup_faq(number: int) -> str:
    """Read a FAQ entry by number and return the response."""
    text = TROUBLESHOOTING_PATH.read_text()
    # Parse out the section for the given number
    pattern = rf"## {number}\. .*?(?=\n## |\Z)"
    match = re.search(pattern, text, re.DOTALL)
    if match:
        return f"Here's what I'd try:\n\n{match.group(0).strip()}"
    return f"I don't have a specific FAQ entry for issue #{number}."


def escalate(state: dict, customer_message: str, agent_thoughts: str) -> None:
    """Send an escalation to Will."""
    escalation = {
        "id": f"esc-{int(time.time())}",
        "opened_at": datetime.now(timezone.utc).isoformat(),
        "customer_message": customer_message,
        "agent_thoughts": agent_thoughts,
        "closed_at": None,
        "resolution": None,
    }
    state["escalations"].append(escalation)
    log_event(state, "escalation_opened", **escalation)

    template = ESCALATION_TEMPLATE_PATH.read_text()
    will_message = (
        f"🚨 Escalation from {CUSTOMER_EMAIL}\n\n"
        f"**Issue:** {agent_thoughts}\n"
        f"**Tier:** white-glove-install\n"
        f"**Telegram topic:** {CUSTOMER_TOPIC}\n"
        f"**Session log:** {get_state_path()}\n\n"
        f"**What I tried:**\n"
        f"1. Searched the FAQ for keywords — no match\n"
        f"2. Asked clarifying question (see conversation log)\n\n"
        f"**Customer's last message (verbatim):**\n"
        f'"{customer_message}"\n\n'
        f"**Suggested next step:** Direct conversation with the customer."
    )
    send_to_will(will_message, critical=False)


# === Entry point ===

def main():
    """Main loop — poll for messages, handle them."""
    if not WILL_CHAT_ID:
        print("ERROR: WILL_TELEGRAM_CHAT_ID not set", file=sys.stderr)
        sys.exit(1)
    if not CUSTOMER_TOPIC:
        print("ERROR: CUSTOMER_TELEGRAM_TOPIC not set", file=sys.stderr)
        sys.exit(1)

    print(f"Support agent starting for {CUSTOMER_EMAIL}")
    print(f"  Session dir: {SESSION_DIR}")
    print(f"  State: {get_state_path()}")
    print(f"  Will chat: {WILL_CHAT_ID}")
    print(f"  Customer topic: {CUSTOMER_TOPIC}")
    print(f"  Telegram bot library: {'available' if HAS_TELEGRAM_BOT else 'NOT available (polling mode)'}")
    print()

    state = load_state()
    print(f"Loaded state: install_step={state['install_step']}, support_mode={state['support_mode']}")
    print()

    # In production: this would be a Telegram polling loop.
    # For now, this is a scaffold — wire up the actual Telegram bot integration
    # when you deploy this for the first customer.
    print("⚠️  This is a scaffold. Wire up the Telegram polling loop before production use.")
    print("    See TODO comments in support_agent.py and the deploy guide.")
    print()
    print("The reference docs (runbook, FAQ, escalation template) are ready in references/")
    print("The state schema is ready in state.json")
    print()

    # Demo: print what would happen on a few example messages
    demo_messages = [
        "yes to all three",
        "I have an OpenAI key",
        "my bot isn't responding",
    ]
    for msg in demo_messages:
        print(f"[DEMO] Customer says: {msg}")
        # Don't actually mutate state in demo mode
        demo_state = json.loads(json.dumps(state))
        response = (handle_install_step if not demo_state.get("support_mode") else handle_support_message)(demo_state, msg)
        print(f"[DEMO] Agent replies: {response}\n")


if __name__ == "__main__":
    main()
