# Escalation Message Template

Use this when you need to hand a customer issue to Will. Send via `send_message` to `WILL_TELEGRAM_CHAT_ID`.

## Template

```
🚨 Escalation from {customer_email}

**Issue:** {one-line description}
**Tier:** {white-glove-install | support | etc.}
**Customer uptime:** {days since install, or "n/a — pre-install"}
**Telegram topic:** {link to topic}
**Session log:** {path to state.json}

**What I tried:**
1. {attempt 1 + result}
2. {attempt 2 + result}

**What I think is happening:**
{diagnosis, or "I don't know"}

**Customer's last message (verbatim):**
"{their message}"

**Suggested next step:**
{what I think Will should do — quick fix, jump on Zoom, refund, etc.}
```

## When to send

- Issue is in TROUBLESHOOTING.md but the fix didn't work after 2 attempts
- Issue is NOT in TROUBLESHOOTING.md
- Customer asks for a human explicitly
- Customer is hostile, frustrated, or asking for a refund
- You're past the 90-minute mark on an install and it's not working
- The customer has a non-standard setup (ARM Mac, weird Linux, etc.)

## What NOT to include

- The customer's API keys (NEVER paste these)
- Long logs (link to the file, Will can read it)
- Multiple separate issues in one escalation (one issue per escalation, keeps it clean)
- "I think I should handle this" — Will decides, not you

## Tone

Be direct. Will needs:
- What broke
- What you tried
- Your best guess
- The exact customer message

He doesn't need:
- A long apology
- The customer's life story
- Your reasoning for why you couldn't fix it

## After sending

Tell the customer:

> I've handed this off to Will. He'll be in touch in the next few hours. If it's urgent, you can email him at {email}.

Then STOP working on the issue. Don't keep trying things in parallel. Will is now on it.

## When Will responds

When Will replies (he'll reply in the same Telegram topic or in the support-agent's main thread), update `state.json`:

```json
{
  "escalations": [
    {
      "id": "...",
      "opened_at": "...",
      "closed_at": "...",
      "issue_summary": "...",
      "resolution": "...",
      "will_involvement_minutes": 30
    }
  ]
}
```

This data feeds the weekly review. Will needs to know: how many escalations, how long they take, what the common patterns are.

## Quiet hours

If `SUPPORT_QUIET_HOURS` is set (e.g., "22:00-08:00"), don't send non-critical escalations during those hours. Buffer them, send at 8am. Critical escalations (customer is angry, data loss, security issue) override quiet hours.
