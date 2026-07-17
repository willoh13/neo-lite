# NEO Operator Support Agent

A specialized AI agent that does the white-glove install work for NEO Operator customers, so Will doesn't have to be on every Zoom call.

## What it does

- **Drives the install** end-to-end with the customer over Telegram
- **Handles first-7-day support** — looks up the FAQ, walks the customer through fixes
- **Escalates to Will** when it can't solve something in 2 attempts
- **Logs everything** so Will can review what worked and what to put in the next FAQ

## When to use this

You (Will) only need to spin this up when a customer buys the $2,499 install. The agent handles the delivery. You handle the escalations.

## How to spin it up

When a customer pays:

```bash
# 1. Create the customer's Telegram topic (if not already)
# 2. Get the customer's email + topic ID
# 3. Start the support agent

export CUSTOMER_EMAIL="jane@example.com"
export CUSTOMER_TELEGRAM_TOPIC="<topic_id>"
export WILL_TELEGRAM_CHAT_ID="<your_telegram_id>"

python3 /home/neoagent/neo-operator/parts/support-agent/support_agent.py
```

The agent will:
1. Create `~/support-sessions/<customer>/state.json`
2. Send the customer a greeting in their Telegram topic
3. Walk them through the install runbook
4. Stay in support mode for 7 days post-install

## Files in this Part

| File | Purpose |
|---|---|
| `SKILL.md` | The system prompt — load this if spawning a Hermes agent for this role |
| `support_agent.py` | The actual agent code (Telegram polling, message routing, FAQ lookup) |
| `references/INSTALL-RUNBOOK.md` | The install flow, step by step |
| `references/TROUBLESHOOTING.md` | The 20 most common issues with fixes |
| `references/ESCALATION-TEMPLATE.md` | The escalation message format |

## What's still TODO

This is a scaffold. Before the first customer:

- [ ] Wire up actual Telegram polling (currently has placeholders)
- [ ] Add the install runbook steps 1-6 (currently only step 0 is implemented)
- [ ] Test the full install flow with a real customer
- [ ] Set up the weekly review of session logs to update the FAQ
- [ ] Add metrics: escalation rate, time-to-resolution, customer satisfaction

## Performance targets

- 80% of installs complete without Will escalation
- <5 min response time during support hours
- <2 attempts before escalation
- <1 escalation per install on average

## Why this exists

Will is the bottleneck for any service business. This agent makes the install product *scalable* — the same delivery quality whether you're doing 1 install a month or 10.

The customers don't care if it was Will or an agent. They care that they have a working AI chief of staff on their phone 2 hours after they paid.

## Future improvements

- Multi-language support (Spanish, Mandarin, Hindi)
- Voice install (customer calls a number, agent walks them through it)
- Async install (customer starts, leaves, comes back to a working bot)
- Self-improving FAQ (agent auto-adds FAQ entries from successful escalations)
