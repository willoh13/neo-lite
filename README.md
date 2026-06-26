# NEO Lite — Your AI Chief of Staff

**5 minutes. One command. Your own JARVIS.**

NEO Lite is a free, self-hosted AI agent that remembers who you are,
delegates tasks, researches the web, and helps you execute — all from
your terminal, Telegram, or web browser.

## Features

- **Persistent memory** — remembers you across sessions
- **Web research** — search and extract content from any site
- **File management** — read, write, organize your projects
- **Task delegation** — spawn sub-agents for parallel work
- **Cron jobs** — scheduled tasks that run automatically
- **First-run wizard** — answers 3 questions and knows who you are

**Free tier limits:** 5 conversations per day, 1GB RAM, no GPU required.
**License keys unlock more:** Get a `NEO-EVAL` key for a 14-day unlimited trial, or a `NEO-MASTER` key for unlimited forever (free for affiliates).

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/engine/install/) installed
- A DeepSeek API key ([get one free](https://platform.deepseek.com/api_keys))

### Setup (takes 2 minutes)

```bash
# 1. Download NEO Lite
git clone https://github.com/neocloud/neo-lite.git
cd neo-lite

# 2. Add your API key
cp .env.example .env
# Edit .env — paste your DEEPSEEK_API_KEY

# 3. Launch NEO Lite
docker compose up -d

# 4. Open the chat
open http://localhost:8080
```

That's it. Answer 3 questions and you'll be talking to your own
AI Chief of Staff.

## Chat from Telegram

Want to talk to NEO from your phone?

1. Create a bot with [@BotFather](https://t.me/botfather) on Telegram
2. Add the token to `.env`:
   ```
   TELEGRAM_BOT_TOKEN=your_bot_token
   TELEGRAM_ALLOWED_USERS=your_user_id
   ```
3. Restart: `docker compose restart`

## Upgrading

Need more than 5 conversations per day? You have three options:

**Option 1: Get a license key** (free, no credit card)
- **NEO-EVAL-XXXX** — 14-day unlimited trial
- **NEO-MASTER-XXXX** — unlimited forever (affiliates/influencers)
- Drop the key into your `.env` file: `NEO_LICENSE_KEY=NEO-EVAL-XXXX`
- Restart: `docker compose restart`

**Option 2: Upgrade to a paid plan**

| Plan | Price | Conversations | Support |
|------|-------|--------------|---------|
| **Lite** (free) | $0 | 5/day | Community |
| **Blueprint** | $297 one-time | Unlimited | Video walkthroughs |
| **Cloud** | $97-197/mo | Unlimited | Priority |
| **DFY** | $1,997-2,997 one-time | Unlimited | White-glove setup |

→ [neocloud.ai/pricing](https://neocloud.ai/pricing)

**Option 3: Add capability Parts** (modular skill packs)

```bash
neo parts list              # See what's available
neo parts add scraper       # Web scraping + extraction
neo parts add researcher    # Deep research agent
neo parts add planner       # Long-horizon planning
neo parts add memory        # Persistent knowledge graph
```

After installing, restart: `docker compose restart neo-lite`.

## Project Structure

```
neo-lite/
├── docker-compose.yml   # One command to run
├── .env.example         # API keys template
├── config/
│   └── config.yaml      # Hermes Agent configuration
├── scripts/             # NEO's custom tools
├── skills/              # NEO's reusable workflows
├── entrypoint.sh        # First-run wizard + daily limit
└── README.md            # This file
```

## Support

- Issues: [github.com/neocloud/neo-lite/issues](https://github.com/neocloud/neo-lite/issues)
- Community: [Discord](https://discord.gg/neocloud)

---

Built with [Hermes Agent](https://hermes-agent.nousresearch.com) by Nous Research.
