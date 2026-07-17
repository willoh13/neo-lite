# NEO Operator — Your AI Chief of Staff

**~10 minutes. Telegram-first. Your own personal AI agent.**

NEO Operator is a self-hosted AI partner that grows with you. Bring your own API
key from any provider (DeepSeek, OpenAI, Anthropic, Gemini, Grok, Groq,
Ollama, or OpenRouter), point Docker at it, and you have a personal AI in
10 minutes — running on your hardware, remembering who you are, ready to
chat from Telegram, Discord, or your terminal.

---

## What you get on day one

- **Persistent memory** — remembers you across sessions and restarts
- **Telegram chat** — talk to NEO from your phone (recommended)
- **Discord / terminal** — also supported
- **Scheduled tasks (cron)** — NEO runs tasks on a schedule
- **No rate limits** — unlimited conversations, BYOK means you pay your own model provider
- **Free, open source** — no license keys, no tiers, no asterisks. See [docs/services.md](docs/services.md) for the white-glove setup offer
- **70+ bundled skills** — web research, file ops, GitHub, email, video, etc.
- **Modular Parts** — install add-on capability packs (scraper, researcher, planner)

---

## What makes NEO different

Most AI tools are chatbots. NEO is the **first JARVIS you actually own** — and
unlike Iron Man, you can name yours whatever you want.

| Chatbot | NEO Operator |
|---|---|
| Forgets you the moment the window closes | Remembers your name, your business, your preferences — across sessions and across machines |
| One model, one provider, one bill | Bring any API key from any provider. Switch any time. No lock-in. |
| Stays the same forever | Skills keep growing — web research, code review, email drafting, video editing, image gen, and more. The library updates itself. |
| Runs in someone else's cloud | Runs on YOUR hardware. Your data, your models, your rules. |
| You adapt to it | It adapts to you. Learns your voice, your tools, your workflow. |
| One name for everyone | You name it. It remembers its name. It introduces itself. |

The longer you use it, the better it gets. The longer you don't use it, the
more you're missing. That's the JARVIS effect.

---

## Quick Start — pick your platform

### I have never used an API key before (5th grade path)

**Windows (10/11)** — no git, no command line, no problem.

1. Download the latest release: https://github.com/willoh13/neo-operator/releases/latest
2. Download `neo-operator-windows.zip`
3. Extract the ZIP somewhere you'll remember (e.g., `Documents\neo-operator`)
4. Right-click `install-windows.bat` → **Run as administrator**
5. Answer a few simple questions:
   - "Do you want NEO to use DeepSeek, OpenAI, or something else?" (pick one)
   - "Paste your API key" (you'll get a link to the free signup page if you don't have one)
   - "Do you want to talk to NEO on Telegram?" (yes — takes 2 min, walks you through it)
6. Wait ~10 minutes (first time only, mostly downloading Docker)
7. Done. Message your new bot on Telegram and say hello.

**Mac / Linux** — slightly more command line, same idea.

```bash
git clone https://github.com/willoh13/neo-operator.git
cd neo-operator
./install.sh      # this is the Mac/Linux version of install-windows.bat
```

The installer asks the same questions: which provider, what's your key, want Telegram. ~10 min total.

### I already have an API key (faster path)

```bash
git clone https://github.com/willoh13/neo-operator.git
cd neo-operator
cp .env.example .env
nano .env   # paste your key, save, exit
docker compose up -d
```

Total: ~3 minutes if you have Docker already.

### I have an OpenAI / Anthropic / Claude / ChatGPT subscription

Same as above. In `.env`, fill in the variable for your provider:

- OpenAI / ChatGPT → `OPENAI_API_KEY`
- Anthropic / Claude → `ANTHROPIC_API_KEY`
- Google Gemini → `GOOGLE_API_KEY`
- xAI Grok → `XAI_API_KEY`
- Groq → `GROQ_API_KEY`
- OpenRouter (200+ models in one key) → `OPENROUTER_API_KEY`
- Local Ollama → `OLLAMA_BASE_URL` (no key needed if running locally)
- DeepSeek (cheapest paid option, ~$0.50/mo casual) → `DEEPSEEK_API_KEY`

Don't have any of these? Start with DeepSeek — free to sign up, ~$0.50/month
for typical use. Get a key here: https://platform.deepseek.com/api_keys

### I want to talk to NEO on Telegram (recommended)

Takes 2 minutes, lets you message your AI from your phone.

1. Open Telegram on your phone
2. Search for `@BotFather` (blue checkmark, official bot)
3. Send `/newbot`
4. BotFather asks for a name → type whatever you want
5. BotFather asks for a username → type something unique ending in `bot`
6. **Copy the token** BotFather sends you (looks like `7123456789:AAH...xyz`)
7. Find your numeric user ID: search for `@userinfobot` in Telegram, send it any message
8. Add both to `.env`:
   ```
   TELEGRAM_BOT_TOKEN=*** =123456789
   ```

---

## Make it yours (name, voice, look)

NEO is Will's AI. Yours needs a name.

The first time you start NEO Operator, the wizard will ask you to:

1. **Pick a name** — something you'll actually say out loud. "Hey Atlas, what's on my calendar?" feels different from "Hey Assistant." Suggestions: Atlas, Friday, Nova, Jinx, Sage, Echo, Cal, Iris. The wizard's default is "Assistant" if you skip.
2. **Pick a voice** — five built-in tones (casual, formal, warm, terse, sarcastic), or drop a `personality.md` file in your NEO Operator folder for a fully custom voice. See `examples/personalities/` for starter templates.

Both go into your `.env` automatically:

```bash
NEO_AI_NAME=Atlas
NEO_AI_TONE=casual
```

Change them any time. Restart the container for changes to take effect.

**Look (your Telegram bot's face):**

Your Telegram bot's name, avatar, and bio are how people see your AI. Set them in 30 seconds with @BotFather:

1. Open Telegram, message `@BotFather`
2. Send `/setname` → pick a new name
3. Send `/setuserpic` → upload an avatar

We include a starter pack of 6 SVG avatars in `assets/avatars/`:

| Avatar | Vibe |
|---|---|
| `jarvis-classic.svg` | Cyan concentric circles, full JARVIS HUD |
| `minimal-dark.svg` | Dark, purple/blue gradient ring, clean |
| `cyan-orb.svg` | Glowing orb with ripples |
| `friendly-gradient.svg` | Cyan-blue-purple with a subtle smile |
| `terminal-mono.svg` | Black/white `>_` prompt for developers |
| `light-classic.svg` | White background, dark "A" |

Open the SVG in any browser, screenshot or export as 512x512 PNG, then upload via `/setuserpic`. See `assets/avatars/README.md` for full instructions and how to customize.

> **Coming soon:** A web UI for NEO Operator. For v1, Telegram + terminal are the only ways to chat. The web UI is the next thing we build.

---

## What can NEO actually do on day one?

Out of the box, NEO comes with 70+ skills across these areas:

- **Web research** — search, read pages, summarize, save findings
- **File operations** — read your files, write files, organize your projects
- **Code** — review PRs, run tests, fix bugs, scaffold new projects
- **Email** — read your inbox, draft replies, send when you approve
- **Calendar** — check your schedule, add events
- **GitHub** — open PRs, review code, manage issues
- **Video & image** — generate, edit, transcribe
- **Memory** — remember who you are, what you're working on, your preferences

The skill library grows over time. NEO is on a continuous improvement cycle —
the same way Iron Man's JARVIS got smarter with every movie. The 70 skills
shipped today are the floor, not the ceiling.

---

## Under the hood (for the curious)

NEO Operator runs on top of [Hermes Agent](https://hermes-agent.nousresearch.com/docs) —
an open-source agent framework maintained by Nous Research. You don't need to
install or configure Hermes separately; it's bundled in the container.

**Why this matters for you:**

- ✅ Real team, active project, regular updates
- ✅ Works with any OpenAI-compatible model
- ✅ Well-documented at hermes-agent.nousresearch.com/docs

**If you're a developer** and want to extend NEO, customize agent behavior,
build new skills, or contribute back upstream, see the [Developer Guide](docs/developer.md).

---

## The 5-minute test (verify it actually works)

After install, send this exact message to your Telegram bot:

```
What model are you and what skills do you have?
```

You should get a response that:

1. Names the model you're using (e.g., "I'm running on DeepSeek Chat" or
   "I'm using GPT-4o via your OpenAI key")
2. Lists at least 10 of its skills
3. Ends with a question back to you (NEO is curious by default)

If you get that, you're done. Go build something.

---

## What this is NOT yet

- ❌ A web app. There is no browser UI in v1.0.0. All chat goes through
  Telegram, Discord, or the terminal. **(Web UI is next on the roadmap — see "Make it yours" above for what to expect.)**
- ❌ A replacement for human judgment. NEO is a partner, not a boss.
- ❌ Free for unlimited use. NEO Operator is free and open source, no asterisks.
  Paid engagements are white-glove setup (Will's time), not access.
  See [docs/services.md](docs/services.md).

---

## Getting help

- 📖 Docs: https://hermes-agent.nousresearch.com/docs
- 💬 Community: [Discord link]
- 🐛 Bugs: github.com/willoh13/neo-operator/issues
- ✉️ Direct: reply to the email that sent you this link

If you get stuck, send the error message to the bot — NEO can usually
figure out what went wrong.
