# 🚀 NEO Operator — Free AI Chief of Staff

**5 minutes. One command. Your own JARVIS.**

## What it does

NEO Operator is a free AI agent that **remembers you**, **researches the web**, **manages your files**, and **delegates work to sub-agents** — all running on YOUR machine, controlled by YOU.

Built on [Hermes Agent](https://hermes-agent.nousresearch.com) by Nous Research.

## 60-second pitch (steal this for DMs, emails, posts)

> I built a free AI Chief of Staff that lives on your computer. It remembers who you are, researches anything, manages your projects, and runs sub-agents in parallel. Setup is one Docker command. Uses your own DeepSeek API key (~$0.50/month). Free tier is 5 conversations/day to start. Want a copy? [github.com/beecurrent/neo-lite]

## What people get

✅ First-run wizard — 3 questions, knows who you are
✅ Persistent memory across sessions (your own SOUL.md)
✅ Web search + content extraction
✅ File management + project organization
✅ Sub-agent delegation (parallel research)
✅ Cron jobs (scheduled tasks)
✅ Telegram integration (chat from your phone)
✅ Add-on Parts system (Scraper, Researcher, etc.)
✅ Free forever — no credit card, no upsells on the free tier

## Quick Start (90 seconds)

```bash
# 1. Get a free DeepSeek API key
#    https://platform.deepseek.com/api_keys
#    (uses ~$0.50/month for casual use)

# 2. Run this on your machine (Docker required)
git clone https://github.com/beecurrent/neo-lite.git
cd neo-operator
cp .env.example .env
# paste your DEEPSEEK_API_KEY into .env
docker compose up -d

# 3. Open http://localhost:8080 and chat
```

That's it. Answer 3 questions and you're talking to your own NEO.

## Common questions (handles 80% of "yeah but"s)

**Q: Is my data private?**
A: Yes. Runs on YOUR machine. Memory, files, conversations never leave your box. You only call the LLM API (DeepSeek / OpenAI / etc.) for the actual AI reasoning.

**Q: What does it cost?**
A: Free tier: 5 conversations/day. API cost is ~$0.50/mo using DeepSeek. Optional upgrades: $297 Blueprint, $97-197/mo Cloud, $1,997-2,997 DFY (we ship you a pre-configured mini PC).

**Q: I don't have Docker.**
A: Grab [Docker Desktop](https://docker.com) — takes 2 minutes, free.

**Q: I'm not technical.**
A: We have a Done-For-You tier ($1,997) where we ship you a pre-configured mini PC that boots up and starts working. Plug it in, done.

**Q: Can it access my files?**
A: Yes, files inside the Docker container. Point it at any folder you want via volumes in `docker-compose.yml`.

**Q: Does it replace ChatGPT?**
A: It's a different layer. ChatGPT is a single conversation. NEO is an agent that remembers you, plans, delegates, runs tasks on a schedule, and integrates with your tools.

## Upgrade tiers (for when they want more)

| Tier | Price | What they get |
|------|-------|---------------|
| **Free** | $0 | 5 convos/day, all core features |
| **Trial** | $0 (NEO-EVAL key) | 14 days unlimited, no credit card |
| **Master** | Free (NEO-MASTER key) | Unlimited, for affiliates/influencers |
| **Blueprint** | $297 one-time | Unlimited convos + setup playbook |
| **Cloud** | $97-197/mo | Hosted, no install, priority support |
| **DFY** | $1,997-2,997 | Pre-configured mini PC, we set it up |

→ https://beecurrent.com/pricing

## Add-on Parts (plug-in skill packs)

After installing, users can extend their NEO with modular Parts:

```bash
neo parts list            # See what's available
neo parts add scraper     # Web scraping
neo parts add researcher  # Deep research agent
neo parts add planner     # Long-horizon planning
neo parts add memory      # Persistent knowledge graph
```

Available Parts:
- **Scraper** — Scrape web pages + extract structured content
- **Researcher** — Deep research agent with parallel sub-searches
- **Planner** — Long-horizon planning with task breakdown
- **Memory** — Persistent knowledge graph across sessions

## How to share this

**Best channels (in order):**

1. **Direct DM to founders** you know — paste the 60-second pitch + the github link
2. **Email your list** — subject: "I built a free AI Chief of Staff, here's the link"
3. **Post on X/Threads/LinkedIn** — your founder story + this page
4. **Reply to anyone** asking "what's an AI agent I can actually use?" with this link
5. **Give to 5 people this week** and ask them to give it to 5 more

## What you need to do BEFORE sharing

1. Push the code to a real GitHub repo (currently `git clone https://github.com/beecurrent/neo-lite.git` won't work — it's still local)
2. Set up `beecurrent.com/pricing` (or wherever) so the upgrade link works
3. Set up an email responder so upgrade requests don't get lost

---

**This is the part where the rubber meets the road.** Every copy of NEO Operator someone installs is a future customer. Free tier is the funnel. Blueprint/Cloud/DFY are the monetization.

Give away 10 copies this week. Then 10 more. Then 100. The compounding is in the network.

— NEO