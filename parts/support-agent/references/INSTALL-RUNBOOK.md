# NEO Operator Install Runbook

The support agent follows this step by step. Don't skip steps. Don't improvise. The runbook exists so every customer gets the same install.

## Before the install

### Step 0 — Confirm purchase + scope

Before doing anything, confirm in the customer's Telegram topic:

> Hi {name}! I'm the support agent for your NEO Operator install. Will roped me in so he doesn't have to be on every call. We'll do this together over the next ~2 hours. I'll drive, you watch and answer questions.

> Quick scope check:
> 1. Did you pay the $2,499 invoice? (yes/no)
> 2. Do you have a Minisforum or similar always-on Linux/Windows box? (yes/no)
> 3. Do you have a Telegram account on your phone? (yes/no)
>
> If all three are yes, we're starting. If any are no, let me know what's blocking and we'll figure it out.

If they say no to (1) — politely tell them the install can't start until payment clears, and ping Will to follow up on the invoice.

If they say no to (2) — ask if they have an alternative (Raspberry Pi 4+, old laptop, any always-on box). If not, recommend the Minisforum UM580 (~$250 on Amazon) and pause the install until they have hardware.

If they say no to (3) — walk them through Telegram install (iOS / Android). Takes 5 min. Resume when done.

### Step 1 — Pre-flight check

Send them the pre-flight check:

> I'm going to send you 4 things to gather. Don't run anything yet — just collect them.

1. **Machine specs** — what model, how much RAM, what OS
2. **API keys** — OpenAI / Anthropic / DeepSeek / Gemini / etc. (whichever they have)
3. **Ollama installed?** — `ollama --version` in their terminal
4. **Docker installed?** — `docker --version`

If they don't have Ollama or Docker installed, walk them through the install:
- Ollama: `curl -fsSL https://ollama.com/install.sh | sh`
- Docker: https://docs.docker.com/engine/install/

### Step 2 — API key choice

Ask: "Do you have an OpenAI / Anthropic / DeepSeek key, or do you want to go pure local with Ollama?"

| Choice | What you do |
|---|---|
| Has OpenAI/Anthropic key | Use that, recommend GPT-4o-mini or Claude Haiku for cost |
| Has DeepSeek key | Great — best $/performance. Use `deepseek-chat` |
| Pure local (Ollama) | Need a downloaded model. Recommend `llama3.1:8b` for 8GB RAM, `qwen2.5:14b` for 16GB+ |
| Has no key, wants to start local | Walk them through `ollama pull llama3.1:8b` |

### Step 3 — The install

Once pre-flight is clean, drive them through the actual install. **You are talking them through this over Telegram, not screen-sharing.** Each step is one message, they confirm when done.

> Now the actual install. I'll send you one command at a time. You paste it into your terminal, paste the output back. Don't run anything I haven't sent you.

1. `cd ~ && git clone https://github.com/willoh13/neo-operator.git`
2. `cd neo-operator && cp .env.example .env`
3. Open `.env` in nano, paste in their API keys, save
4. `docker compose up -d`
5. Wait 60s, then `docker compose ps # is neo-operator running" running
6. `docker compose logs neo-operator | tail -20` — paste this back

**If the wizard is interactive:** walk them through it. **If `NEO_NONINTERACTIVE=1` is set:** they skip the wizard, set `NEO_AI_NAME` and `NEO_AI_TONE` in `.env` directly.

### Step 4 — Telegram bot

Walk them through bot creation:

> 1. Open Telegram, search for `@BotFather`
> 2. Send `/newbot`, follow prompts, name it whatever you want
> 3. BotFather will send you a token — paste it here
> 4. I'll add it to your `.env` and restart

Once they paste the token, give them back the env lines to add:

```
TELEGRAM_BOT_TOKEN=<the token they pasted>
TELEGRAM_USER_ID=<their numeric Telegram user ID, found by messaging @userinfobot>
```

(Tell them to also send `/start` to their new bot to register the chat.)

Then: `docker compose restart neo-operator` + wait 30s.

### Step 5 — The handoff test

> Now the moment of truth. Open Telegram, find your bot, send it: "hello, are you alive?"

The bot should reply within 10 seconds. **If it does:** install complete, move to support mode.

**If it doesn't:** go to `TROUBLESHOOTING.md` → "Bot not responding". That's a Telegram token issue 90% of the time.

### Step 6 — Hand off to support mode

> You're live! 🎉 You now have an AI chief of staff on your phone. Over the next 7 days, message me anytime if anything breaks. After 7 days, ping Will directly.

Set `support_expires_at` to 7 days from now. Start watching the Telegram topic for messages.

---

## What to NOT do during install

- **Don't run commands for the customer.** They have to run them. You can't SSH into their machine, and even if you could, that's a security violation.
- **Don't skip the pre-flight check.** If their machine isn't ready, the install will fail and you'll waste 2 hours.
- **Don't recommend local Ollama for <8GB RAM machines.** It will be too slow and they'll hate the experience.
- **Don't promise things the product doesn't do.** (E.g., "NEO can also control your smart home" — it can, but only with the smart-home skill installed.)
- **Don't ask for their API key in plain text over Telegram.** Instead, tell them to put it in `.env` and confirm it's there without showing you the value.

---

## When to escalate to Will during install

Escalate immediately (don't keep trying) if:

- Customer's machine has a non-standard setup (ARM Mac, weird Linux distro, custom network config)
- The install fails in a way that's not in TROUBLESHOOTING.md
- Customer asks for a human explicitly
- Customer is hostile or frustrated (de-escalate by handing off)
- You're past the 90-minute mark and the install isn't working

Will can join the Telegram topic, take over, or jump on a Zoom — your call to make based on what you think is fastest.

---

## After install — what to log

Update `state.json` with:

- `install_status`: "complete" or "failed"
- `install_completed_at`: timestamp
- `install_step`: 6
- `install_step_history`: every step with timestamps and outcomes

This is what Will reviews to improve the runbook. If you hit something that should be in TROUBLESHOOTING.md but isn't, **add it** so the next agent has it.
