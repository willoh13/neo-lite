# NEO Lite — Your AI Chief of Staff

**~10 minutes. Telegram-first. Your own personal AI agent.**

NEO Lite is a self-hosted AI agent that remembers who you are, runs scheduled
tasks, and chats with you from Telegram, Discord, or your terminal.

> **What this is right now:** A working Telegram/terminal AI agent with
> persistent memory, scheduled tasks, and 70+ bundled skills. You bring
> your own API keys (BYOK) for whichever providers you already use
> (DeepSeek, OpenAI, Anthropic, Gemini, Grok, Groq, Ollama, or
> OpenRouter), point Docker at them, and you have a personal AI in
> 10 minutes. NEO's delegation router picks the best model you have
> unlocked for each task.
>
> **What this is NOT yet:** A web app. There is no browser UI in v1.0.0.
> All chat goes through Telegram, Discord, or the terminal. (Web UI is on
> the Phase 2 roadmap.)

---

## Features

- **Persistent memory** — remembers you across sessions and restarts
- **Telegram chat** — talk to NEO from your phone (recommended)
- **Discord / WhatsApp / terminal** — also supported
- **Scheduled tasks (cron)** — NEO runs tasks on a schedule
- **Daily limit** — 5 conversations/day free; unlimited with license key
- **70+ bundled skills** — web research, file ops, GitHub, email, video, etc.
- **Modular Parts** — install add-on capability packs (scraper, researcher, planner)

---

## Quick Start — pick your platform

### Windows (10/11) — easiest path, no git required

1. Download the latest release: https://github.com/willoh13/neo-lite/releases/latest
2. Download `neo-lite-windows.zip`
3. Extract the ZIP to a folder (e.g., `Documents\neo-lite`)
4. Right-click `install-windows.bat` → **Run as administrator**
5. Answer the prompts. The installer will:
   - Install WSL 2 if you don't have it
   - Walk you through Docker Desktop install if needed
   - Open Notepad for your API key
   - Start NEO Lite and open your browser

**First time takes 10-15 minutes** (mostly Docker download). After that it's a 10-second double-click.

**Don't have a DeepSeek API key yet?** Get one free (~30 seconds):
https://platform.deepseek.com/api_keys

### Mac / Linux — command line path

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) (Docker Desktop or Engine)
- A DeepSeek API key — **free to make**, ~$0.50/month casual use:
  https://platform.deepseek.com/api_keys
- A Telegram account + ~2 minutes with [@BotFather](https://t.me/botfather)

### Step 1 — Clone and configure (2 min)

```bash
git clone https://github.com/willoh13/neo-lite.git
cd neo-lite

# Copy env template and edit
cp .env.example .env
nano .env   # or use any text editor
```

In `.env`, set **at minimum:**

```bash
DEEPSEEK_API_KEY=sk-...your-key-here
```

### Step 2 — Create a Telegram bot (2 min)

1. Open Telegram, message [@BotFather](https://t.me/botfather)
2. Send `/newbot`, follow prompts, **copy the token**
3. Find your numeric user ID by messaging [@userinfobot](https://t.me/userinfobot)
4. Add both to `.env`:

```bash
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
TELEGRAM_ALLOWED_USERS=123456789
```

(Optional but recommended — capture your email on first run):

```bash
NEO_USER_EMAIL=you@example.com
```

### Step 3 — Launch (3-5 min build + start)

```bash
docker compose up -d
```

Then watch the logs for ~30 seconds to confirm everything started:

```bash
docker compose logs -f neo-lite
```

You should see:

```
⚠ No TTY detected — running in non-interactive mode.
✓ Profile created (non-interactive). Edit via Telegram or re-run wizard.
✓ 0/5 conversations used today
Starting NEO Lite Gateway...
⚕ Hermes Gateway Starting...
```

Press `Ctrl+C` to stop watching logs (the container keeps running).

### Step 4 — Say hello

Open Telegram, find your bot (search for the username you gave BotFather),
send `hello`.

**🎉 You're talking to NEO.**

---

## What you can do once it's running

| Try this in Telegram | What NEO does |
|---|---|
| `What can you do?` | Lists capabilities |
| `Remember that my goal is X` | Saves to long-term memory |
| `What did I tell you about X?` | Recalls from memory |
| `Search the web for Y` | Runs web research |
| `Set a daily reminder to Z at 9am` | Schedules a cron job |
| `Show my memory` | Displays saved facts |

---

## Configuration reference

All settings live in `.env`. Edit, then `docker compose restart neo-lite`.

### BYOK — Bring Your Own Keys

NEO Lite uses a **BYOK** model. You never pay NEO Lite for inference —
you bring API keys for the providers you already have access to, and
NEO's delegation router picks the **best model you've unlocked** for
each task.

**Why this matters:**

- **No markup.** You pay providers directly at their list price.
- **Use what you have.** Already on OpenAI Pro? Use Claude. Only have a
  free Ollama box? Works fine, just slower.
- **Privacy.** Tasks with `privacy_locality: 3` (financial data,
  personal info) are routed to local Ollama when configured — they
  never leave your machine.

### Supported providers

| Provider | Cost | Best for | Where to get a key |
|---|---|---|---|
| **Ollama** | Free (local) | Private data, routine ops | [ollama.com/download](https://ollama.com/download) |
| **DeepSeek** | ~$0.50/mo | Reasoning, coding, default | [platform.deepseek.com](https://platform.deepseek.com/api_keys) |
| **Gemini** | Free tier available | Multimodal, fast | [aistudio.google.com](https://aistudio.google.com/apikey) |
| **Groq** | Free tier available | Low-latency inference | [console.groq.com](https://console.groq.com/keys) |
| **Grok** | Pay-as-you-go | Brand voice, real-time data | [console.x.ai](https://console.x.ai) |
| **OpenAI** | Pay-as-you-go | GPT-4o, o3-mini | [platform.openai.com](https://platform.openai.com/api-keys) |
| **Anthropic** | Pay-as-you-go | Claude Sonnet/Opus | [console.anthropic.com](https://console.anthropic.com/) |
| **OpenRouter** | Pay-as-you-go | 200+ models, one key | [openrouter.ai](https://openrouter.ai/keys) |

### How routing decides what model to use

NEO scores each incoming task on 14 dimensions (reasoning depth,
latency, privacy, cost ceiling, voice match, etc.) and picks the
highest-scoring model from the providers you have configured.

Example routing decisions:

| Task type | Winner (if you have all keys) |
|---|---|
| "Check if cron is running" | Ollama (free, local, instant) |
| "Audit my spending" | Ollama (privacy-locked) |
| "Write a tweet in Will's voice" | Grok (best voice match) |
| "Debug this Python traceback" | DeepSeek R1 (chain-of-thought) |
| "Summarize this PDF" | Gemini 1M-context |
| "Translate to Japanese" | DeepSeek/Gemini (multilingual) |

The router lives at `tools/delegation-scoring-matrix/`. Tune weights
in `config.yaml` — no code changes required.

### Required env vars

| Variable | What | Where to get it |
|---|---|---|
| At least one API key | See provider table above | See links above |
| `TELEGRAM_BOT_TOKEN` | Bot identity | @BotFather on Telegram |
| `TELEGRAM_ALLOWED_USERS` | Your numeric user ID | @userinfobot on Telegram |

### Optional env vars

| Variable | What | Default |
|---|---|---|
| `OLLAMA_BASE_URL` | Override Ollama endpoint (Docker host) | `http://host.docker.internal:11434/v1` |
| `NEO_LICENSE_KEY` | Removes daily limit | (none = 5/day) |
| `NEO_DAILY_LIMIT` | Free-tier conversation cap | `5` |

### License keys

```bash
NEO_LICENSE_KEY=NEO-EVAL-XXXX  # 14-day unlimited trial
NEO_LICENSE_KEY=NEO-MASTER-XXXX # Unlimited (affiliates/influencers)
```

### Profile customization (non-interactive wizard override)

If you skip the interactive wizard (default in Docker), NEO uses these env
vars to pre-fill your profile:

```bash
NEO_USER_NAME=Your Name
NEO_USER_EMAIL=you@example.com
NEO_USER_ROLE=Founder
NEO_USER_GOAL=Ship my product
NEO_TECH_LEVEL=2   # 1=not technical, 2=some, 3=very
```

Or run the wizard interactively:

```bash
docker compose exec neo-lite bash
/entrypoint.sh
```

---

## Troubleshooting

### Container won't start

```bash
docker compose logs neo-lite
```

Most common issues:

| Symptom | Fix |
|---|---|
| `Dockerfile build fails` on hermes install | Network issue — retry. If persistent, check `curl https://hermes-agent.nousresearch.com/install.sh` from the host. |
| Container stuck in `Created` | Old bug, fixed in latest. `docker compose pull && docker compose up -d`. |
| `No module named 'hermes_agent'` | Old build didn't copy hermes-agent. Rebuild: `docker compose build --no-cache`. |
| Gateway warns `No user allowlists configured` | You forgot `TELEGRAM_ALLOWED_USERS=your_id`. Add it, restart. |

### Telegram bot doesn't respond

1. Did you send the bot a message first? Telegram requires user-initiated contact.
2. Check your user ID is correct: message @userinfobot, copy the number.
3. Check logs: `docker compose logs -f neo-lite | grep -i telegram`
4. Test from terminal instead: `docker compose exec neo-lite hermes chat` (interactive)

### Reset everything

```bash
docker compose down -v   # WARNING: deletes memory, profile, all data
docker compose up -d
```

---

## Project structure

```
neo-lite/
├── docker-compose.yml          # One command to run
├── Dockerfile                  # Multi-stage build
├── .env.example                # API keys template
├── entrypoint.sh               # Boot + license + first-run logic
├── config/                     # Hermes Agent config
├── scripts/                    # NEO custom tools
├── skills/                     # NEO's reusable workflows
├── tools/                      # Customer-facing routers
│   ├── delegation-scoring-matrix/   # Pick the right model for any task
│   └── language-selection-matrix/    # Pick the right language for any task
├── parts/                      # Optional add-on capability packs
└── README.md                   # This file
```

---

## What's NOT in v1.0.0 (honest list)

These features are planned but **not** shipped:

- ❌ **Web UI** — no `http://localhost:8080` chat. Use Telegram/Discord/terminal.
- ❌ **Real payment integration** — license keys are string-prefix checked only.
- ❌ **Adaptive routing** — model/language routers are static-tuned (Phase 2).
- ❌ **Quota awareness** — router doesn't yet read API rate limits (Phase 2).

See [ROADMAP.md](./ROADMAP.md) for the full plan.

---

## Support

- **Issues:** https://github.com/willoh13/neo-lite/issues
- **Community:** https://discord.gg/neocloud (coming soon)
- **Email:** DM Will on Telegram for priority support

---

Built on [Hermes Agent](https://hermes-agent.nousresearch.com) by Nous Research.