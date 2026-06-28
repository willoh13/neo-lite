# NEO Lite — Clean Install Test Checklist (ASUS Duo)

**Purpose:** Verify every step of a fresh install works on this exact machine
**before** sending it to Jeff or anyone else. Check each box only when you
**see the expected output**.

**Target time:** 15-20 minutes (first time), 5 minutes after.

**Date tested:** ___________
**Tester:** ___________
**Result:** ☐ PASS  ☐ FAIL (notes below)

---

## Pre-flight (verify environment)

- [ ] **Open Terminal** on the ASUS Duo (Ctrl+Alt+T or click Terminal icon)
- [ ] **Docker is installed** — run `docker --version`
      - Expected: `Docker version 24.x or higher`
      - If missing: install Docker Desktop for Linux from
        https://docs.docker.com/desktop/install/linux/
- [ ] **Docker Compose is installed** — run `docker compose version`
      - Expected: `Docker Compose version v2.x or higher`
- [ ] **Git is installed** — run `git --version`
      - Expected: `git version 2.x`
- [ ] **Internet works** — run `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | head -3`
      - Expected: bash script content (no errors)
- [ ] **You have a DeepSeek API key** — go to https://platform.deepseek.com/api_keys
      - If not: create account (free), generate key, copy it (starts with `sk-`)
- [ ] **You have Telegram installed** on your phone + ~3 min spare

**⏱ Time check:** ___________ (should be ~2 min)

---

## Step 1 — Create your Telegram bot (do this before installing NEO Lite)

- [ ] Open Telegram on your phone
- [ ] Search for `@BotFather` (blue checkmark, official bot)
- [ ] Send `/newbot`
- [ ] BotFather asks for a name → type: `NEO Lite Test`
- [ ] BotFather asks for a username → type something unique ending in `bot`,
      e.g. `neo_lite_will_test_bot`
- [ ] **Copy the bot token** BotFather sends you (looks like `7123456789:AAH...xyz`)
- [ ] Save it somewhere — you'll paste it in `.env` in 2 min

- [ ] Now find your **numeric user ID**:
      - Search for `@userinfobot` in Telegram
      - Send it any message
      - **Copy the number** it replies with (e.g. `123456789`)

**⏱ Time check:** ___________ (should be ~2 min)

---

## Step 2 — Get the code

Two options:

**Option A — Clone (if you have access):**
```bash
git clone https://github.com/willoh13/neo-lite.git
cd neo-lite
```

**Option B — Use a zip file (easiest for non-technical users):**
- Download `neo-lite.zip` from the link Will sent you
- Unzip it somewhere you can find it (e.g. Desktop)
- Open Terminal, navigate to the unzipped folder:
  ```bash
  cd ~/Desktop/neo-lite    # or wherever you unzipped
  ```

- [ ] **Verify you're in the right place** — run `ls -la`
      - Expected: see `Dockerfile`, `docker-compose.yml`, `README.md`, `entrypoint.sh`, `tools/`, `skills/`

**⏱ Time check:** ___________ (should be ~30 sec)

---

## Step 3 — Configure `.env`

```bash
cp .env.example .env
nano .env    # or: code .env  (VS Code) |  vim .env
```

In the editor, find and **change these three lines:**

```bash
# Find this line:
DEEPSEEK_API_KEY=

# Replace with (your actual key from pre-flight):
DEEPSEEK_API_KEY=sk-...

# Find this line:
# TELEGRAM_BOT_TOKEN=your_bot_token_here
# TELEGRAM_ALLOWED_USERS=your_telegram_user_id

# Replace with (uncomment + fill in):
TELEGRAM_BOT_TOKEN=7123456789:AAH...xyz      # from Step 1
TELEGRAM_ALLOWED_USERS=123456789            # from Step 1
```

Save and exit (Ctrl+X, Y, Enter in nano).

- [ ] **Verify your changes** — run `grep -E "DEEPSEEK_API_KEY|TELEGRAM_" .env`
      - Expected: 3 lines, none empty, none starting with `#`
- [ ] **Sanity check no stray directories** — run `ls -la .env`
      - Expected: shows `-rw-r--r--` (a file, not a directory)

**⏱ Time check:** ___________ (should be ~2 min)

---

## Step 4 — Build the Docker image (slowest step)

```bash
docker compose build
```

- [ ] **Build completes without errors** — Expected final line: `neo-lite  Built`
- [ ] **Build took 1-5 min** — record time: ___________

If build fails:
- [ ] Check the error message. Most common: SSL/network error → just retry.
- [ ] If hermes-agent install fails, check `curl https://hermes-agent.nousresearch.com/install.sh`
      works from your host (network/firewall issue).

---

## Step 5 — Launch (the moment of truth)

```bash
docker compose up -d
```

- [ ] **Container starts** — Expected: prints `Container neo-lite  Started`
- [ ] **Watch the logs** — in a second terminal: `docker compose logs -f neo-lite`
- [ ] **Within 15 seconds, see all 3 lines:**
      - `⚠ No TTY detected — running in non-interactive mode.`
      - `✓ Profile created (non-interactive). Edit via Telegram or re-run wizard.`
      - `✓ 0/5 conversations used today`
- [ ] **See gateway start banner**:
      - `Starting NEO Lite Gateway...`
      - `⚕ Hermes Gateway Starting...`

Press `Ctrl+C` to exit the log viewer (container keeps running).

If you see `exec hermes-agent/venv/bin/hermes: not found` or similar → your
build is missing the hermes-agent copy step. Run:
`docker compose build --no-cache && docker compose up -d`.

**⏱ Time check:** ___________ (should be ~30 sec after build)

---

## Step 6 — Verify the container is healthy

```bash
docker compose ps
```

- [ ] **Container status shows `Up`** (not `Created` or `Exited`)
      - Expected: `neo-lite   Up X seconds   0.0.0.0:8080->8080/tcp`

```bash
docker exec neo-lite ls -la /root/.hermes/ | head -20
```

- [ ] **Files exist inside the container**:
      - `.onboarded` (your marker that wizard completed)
      - `SOUL.md` (your profile file)
      - `user_profile.json` (structured profile)
      - `.daily_count` and `.daily_date`

```bash
docker exec neo-lite hermes --version
```

- [ ] **Hermes responds** — Expected: prints version number (e.g. `0.x.y`)

If this fails → hermes binary is broken → rebuild `--no-cache`.

**⏱ Time check:** ___________ (should be ~1 min)

---

## Step 7 — Talk to NEO via Telegram

- [ ] Open Telegram on your phone
- [ ] Search for the bot username you created in Step 1
      (e.g. `@neo_lite_will_test_bot`)
- [ ] Tap **Start** or send `/start`
- [ ] Send `hello`
- [ ] **NEO responds** within 5-15 seconds

First-message test prompts (do all 5):

- [ ] Send: `what's my name?`
      - Expected: NEO says "Operator" or your NEO_USER_NAME if you set it
- [ ] Send: `remember that my favorite color is blue`
      - Expected: NEO confirms it remembered
- [ ] Send: `what's my favorite color?`
      - Expected: NEO says "blue" (proves memory persistence)
- [ ] Send: `what can you do?`
      - Expected: NEO lists capabilities (chat, memory, web research, cron, etc.)
- [ ] Send: `search the web for the weather in Seattle`
      - Expected: NEO runs web search (or explains if API quota reached)

**⏱ Time check:** ___________ (should be ~2 min)

---

## Step 8 — Test the daily limit (optional, advanced)

- [ ] Check current usage:
      `docker exec neo-lite cat /root/.hermes/.daily_count`
- [ ] Send 5 quick messages to hit the limit (counter goes 0→5)
- [ ] **6th message is blocked** with banner:
      `⏰ You've used 5 conversations today. Limit: 5. Upgrade to continue.`
- [ ] To reset: `docker exec neo-lite bash -c "echo 0 > /root/.hermes/.daily_count"`

This proves the license system works. (For testing, set `NEO_DAILY_LIMIT=100`
in `.env` to avoid hitting the limit during longer tests.)

---

## Step 9 — Test persistence (the critical one)

- [ ] Send NEO a memorable message: `remember my goal is to test NEO Lite end-to-end`
- [ ] **Restart the container:**
      `docker compose restart neo-lite`
- [ ] Wait 10 seconds for it to come back up
- [ ] Send in Telegram: `what's my goal?`
- [ ] **NEO recalls it correctly** — proves memory persists across restarts

If NEO forgot → memory volume is broken. Check:
`docker volume ls | grep neo-lite` — should show `neo-lite_neo-lite-data`.

---

## Step 10 — Test the tools (proves customer-facing features work)

- [ ] Test delegation router from your host:
      `docker exec neo-lite python /opt/hermes/tools/delegation-scoring-matrix/router.py --task-preset ops_health_check --task "is the gateway up?"`
      - Expected: prints the chosen model (likely `ollama:gemma4:e4b` or similar)
- [ ] Test language router:
      `docker exec neo-lite python /opt/hermes/tools/language-selection-matrix/language-router.py --task-preset cron_glue --task "write a daily cleanup script"`
      - Expected: prints chosen language (likely `bash`)

---

## Final checks

- [ ] **Total time elapsed:** ___________
- [ ] **All 10 steps passed:** ☐ Yes  ☐ No
- [ ] **Any unexpected behavior:** ________________________________
- [ ] **Telegram conversation felt natural:** ☐ Yes  ☐ No
- [ ] **Memory persisted across restart:** ☐ Yes  ☐ No
- [ ] **You could imagine Jeff doing this:** ☐ Yes  ☐ No

---

## If anything failed

Copy the relevant `docker compose logs neo-lite` output and the step number
that failed, then send to Will. Common patterns:

| Failure | Most likely cause | Fix |
|---|---|---|
| Build fails on hermes install | Network / firewall | Retry; check curl works |
| Container stuck `Created` | Old buggy build | `docker compose pull && docker compose build --no-cache && docker compose up -d` |
| `No module named 'hermes_agent'` | Missing COPY step | Same as above |
| Telegram bot silent | Wrong user ID | Re-check with @userinfobot |
| Telegram bot "not allowed" | `TELEGRAM_ALLOWED_USERS` not set | Add to `.env`, restart |
| NEO responses are nonsense | Wrong API key or no quota | Verify key at deepseek.com |
| NEO forgets between sessions | Volume not mounted | Check `docker compose ps` shows volume |

---

## Once everything passes

**Congratulations — NEO Lite works on the ASUS Duo.** That means:

1. The Docker image is shippable
2. The Telegram path is the real customer entry point (not the web UI)
3. You can confidently walk Jeff through the same steps
4. You can record a 90-second Loom showing the install → first chat → restart
   → memory test, and use it as the demo for everyone else

**Next:** send this checklist to anyone testing, and post a 60-second video of
Step 7 (the Telegram hello) to your socials as proof it works.