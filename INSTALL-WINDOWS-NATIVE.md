# NEO Lite for Windows — Customer Install Guide
## The 5-Minute Install (No Docker, No WSL, No Linux)

This guide installs **NEO Agent 2** — your personal AI chief of staff — on Windows 10 or 11. It uses the official Hermes Agent installer and adds the NEO personality layer, the full Skills Bundle, and your Telegram bot. Everything is one Python install, no virtual machines, no containers.

**Total install time: 5-10 minutes on a clean machine.**

---

## What you need before you start

Gather these three things. If you don't have them yet, the guide shows you where to get each one. **All three are free.**

1. **A DeepSeek API key** — for the AI's brain. ~$0.50/month for casual use.
   - Get one: https://platform.deepseek.com/api_keys (sign up, click "API Keys", "Create new secret key", copy it)

2. **A Telegram bot token** — for talking to NEO from your phone or desktop.
   - Open Telegram, message **@BotFather**
   - Send `/newbot`
   - Follow the prompts (give it a name like "NEO Agent 2" and a username like "NEOAgent2Bot")
   - BotFather replies with a token like `7123456789:AAH...xyz` — copy the whole thing

3. **Your Telegram user ID** — so only you can talk to your NEO (no one else can).
   - In Telegram, message **@userinfobot**
   - It replies with a number like `123456789` — that's your user ID

**Optional, but recommended:**

4. **A Groq API key** (free, very fast) — backup AI provider. Get one: https://console.groq.com/keys
5. **An xAI Grok API key** — premium AI for real-time data. Get one: https://console.x.ai

You can add more AI providers later. NEO picks the best one for each task automatically.

---

## Part 1 — Install NEO Lite (the easy part)

### Step 1.1: Open PowerShell as Administrator

- Press the **Windows key** (or click the Start button)
- Type `powershell`
- Right-click **"Windows PowerShell"** or **"Terminal"**
- Choose **"Run as administrator"**
- Click **Yes** when Windows asks if you're sure

You should see a blue PowerShell window. The title bar will say "Administrator".

### Step 1.2: Allow script execution (one-time)

Copy and paste this line into PowerShell, then press **Enter**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

If it doesn't print anything, that's fine. If it asks for confirmation, type `Y` and press Enter.

### Step 1.3: Download and run the NEO Lite installer

Copy and paste this whole block into PowerShell and press **Enter**:

```powershell
# Download NEO Lite to your Downloads folder
$downloads = [Environment]::GetFolderPath('UserProfile') + '\Downloads'
$neoZip = "$downloads\neo-lite.zip"
Invoke-WebRequest -Uri 'https://github.com/willoh13/neo-lite/archive/refs/heads/test-public-flag.zip' -OutFile $neoZip
Expand-Archive -Path $neoZip -DestinationPath $downloads -Force
Rename-Item "$downloads\neo-lite-test-public-flag" "$downloads\neo-lite" -Force
Set-Location "$downloads\neo-lite"
Write-Host "NEO Lite downloaded to: $downloads\neo-lite" -ForegroundColor Green
```

Wait for the download. It should take 10-30 seconds. When it's done, the last line will say `NEO Lite downloaded to: C:\Users\<yourname>\Downloads\neo-lite`.

**If you get a red error about "execution of scripts is disabled"**, run Step 1.2 again, then retry.

**If you get a red error about the file being blocked**, run this and try again:
```powershell
Unblock-File "$downloads\neo-lite.zip"
```

### Step 1.4: Download the NEO Skills Bundle

This is the file that gives NEO all its capabilities (scraper, support-agent, planner, researcher, etc.). Paste and Enter:

```powershell
$bundleZip = "$downloads\neo-bundle-v1.0.0.zip"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/willoh13/neo-lite/test-public-flag/dist/neo-bundle-v1.0.0.zip' -OutFile $bundleZip
Expand-Archive -Path $bundleZip -DestinationPath $downloads -Force
Write-Host "Skills Bundle downloaded." -ForegroundColor Green
```

**If the download fails**, paste the exact error and we'll debug. We'll apply the bundle in Step 1.6.

### Step 1.5: Install Hermes Agent (the AI runtime)

This is the official Hermes Agent installer. It installs Python, the runtime, and the `hermes` command. Paste and Enter:

```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

This will:
- Download a small Python tool called `uv` (fast Python package manager)
- Download Hermes Agent (about 50 MB)
- Install it to `%LOCALAPPDATA%\hermes\`
- Add `hermes` to your PATH

**Watch for these prompts:**

1. **"Hermes was installed successfully"** — good, press Enter
2. **A question about which model provider to use** — choose **DeepSeek** (number depends on the menu; usually option 1 or 2)
3. **"Paste your API key"** — paste your DeepSeek key, press Enter. It won't show on screen, that's normal
4. **A question about Telegram** — say **Yes**, then paste your bot token, press Enter, paste your user ID, press Enter

If the installer closes and you're back at the prompt, it worked. Type this to confirm:

```powershell
hermes --version
```

You should see something like `Hermes Agent v0.17.0`. If you see "hermes: The term 'hermes' is not recognized", close PowerShell and re-open it as Administrator (Step 1.1), then try `hermes --version` again.

### Step 1.6: Apply the NEO personality

This copies NEO's voice, memory, and skills into your Hermes install. Paste and Enter:

```powershell
$hermesHome = "$env:LOCALAPPDATA\hermes"
$neoSource = "$downloads\neo-lite"

# Copy personality
Copy-Item -Path "$neoSource\config\*" -Destination "$hermesHome\" -Recurse -Force

# Copy skills
Copy-Item -Path "$neoSource\skills\*" -Destination "$hermesHome\skills\" -Recurse -Force

# Copy tools
Copy-Item -Path "$neoSource\tools\*" -Destination "$hermesHome\tools\" -Recurse -Force

# Copy parts (add-on capability packs)
Copy-Item -Path "$neoSource\parts\*" -Destination "$hermesHome\parts\" -Recurse -Force

Write-Host "NEO Agent 2 personality applied." -ForegroundColor Green
```

You should see `NEO Agent 2 personality applied.` in green.

### Step 1.7: Start NEO

Paste and Enter:

```powershell
hermes gateway start
```

You should see something like `Gateway started, PID: 12345`. The NEO service is now running in the background.

To verify it's actually responding, open Telegram on your phone, search for your bot's username (e.g., `NEOAgent2Bot`), and send it a message:

```
hello, are you alive?
```

**Within 5-10 seconds, your bot should reply.** If it does, congratulations — NEO is installed and working.

---

## Part 2 — Configure your .env (add API keys)

This step is optional. NEO works with just DeepSeek, but adding more providers makes it smarter and gives you fallbacks.

### Step 2.1: Open the .env file

```powershell
notepad "$env:LOCALAPPDATA\hermes\.env"
```

Notepad opens. You'll see a long list of `KEY=` lines. Most are empty.

### Step 2.2: Fill in your keys

Find each line and replace the empty value after `=` with your key. For example:

```
DEEPSEEK_API_KEY=***
```

becomes:

```
DEEPSEEK_API_KEY=sk-7ad...97bc
```

**Required (you should have these from Part 1.5):**
- `DEEPSEEK_API_KEY=*** ← your DeepSeek key

**Optional (recommended for a richer experience):**
- `XAI_API_KEY=` — your xAI Grok key
- `GROQ_API_KEY=` — your Groq key (free, very fast)
- `GOOGLE_API_KEY=` — your Google Gemini key (free tier)

**Telegram (you should have these from Part 1.5):**
- `TELEGRAM_BOT_TOKEN=` — your bot token
- `TELEGRAM_ALLOWED_USERS=` — your user ID (just the number)
- `TELEGRAM_HOME_CHANNEL=` — your user ID (just the number)

**Personality (you can change these anytime):**
- `NEO_AI_NAME=` — default is "Assistant". Change to "NEO Agent 2" or whatever you want
- `NEO_AI_TONE=` — `casual` (default), `formal`, `warm`, `terse`, or `sarcastic`

When you're done, **save the file** (Ctrl+S) and **close Notepad**.

### Step 2.3: Restart NEO so the new keys take effect

```powershell
hermes gateway restart
```

Wait 5 seconds, then test in Telegram again. If you added a new provider (e.g., Groq), NEO will use it for tasks where it's better than DeepSeek.

---

## Part 3 — Daily use

### Starting NEO

NEO starts automatically when you log into Windows. If it's not running:

```powershell
hermes gateway start
```

### Talking to NEO

Open Telegram, message your bot. That's it. Examples:

- "what's on my calendar today?"
- "summarize my last 5 emails"
- "research the best CRM for a 5-person team"
- "draft a reply to Sarah's email about the Q3 numbers"
- "remind me to call the dentist tomorrow at 9am"

### Stopping NEO

```powershell
hermes gateway stop
```

### Checking NEO's status

```powershell
hermes gateway status
hermes logs --tail 20
```

### Updating NEO

When new skills or capabilities are released:

```powershell
# Update the base bundle
cd $env:LOCALAPPDATA\hermes
git pull

# Restart to apply
hermes gateway restart
```

---

## Part 4 — Troubleshooting

### "hermes: The term 'hermes' is not recognized"

Close PowerShell and re-open it as Administrator. The PATH update from the installer only takes effect in new windows.

### NEO doesn't reply in Telegram

1. Check the bot is running: `hermes gateway status`
2. If "stopped", start it: `hermes gateway start`
3. Check the logs: `hermes logs --tail 50` — look for red error lines
4. Verify your bot token is correct: message @BotFather on Telegram, send `/token`, pick your bot, it shows the token
5. Verify your user ID: message @userinfobot on Telegram again

### NEO replies but says "I can't access that"

Some capabilities need extra setup:
- **Email/calendar** — needs Google OAuth, see `docs/google-setup.md` (coming soon)
- **Web search** — works out of the box
- **Code execution** — works out of the box, sandboxed

### Install fails partway through

The Hermes installer creates a log. Send it to support:

```powershell
Get-Content "$env:LOCALAPPDATA\hermes\install.log" -Tail 50
```

Paste the output in your support channel.

### Reset everything and start over

```powershell
hermes gateway stop
hermes uninstall
# Then re-run Part 1 from Step 1.5
```

---

## Part 5 — What's included in the Skills Bundle

This is what you get with NEO Lite (free) and the Pro Skills Bundle ($79). Everything in the bundle is included in the install above.

### Add-on Parts (capability packs)

- **scraper** — Turn any website into structured data. News sites, real estate listings, job boards, you name it.
- **support-agent** — A second AI that helps your customers install and use NEO. Useful if you're reselling.

### Skills (workflows NEO knows how to run)

- **neo-lite-planner** — Breaks big goals into step-by-step plans
- **neo-lite-researcher** — Multi-source research with citations

### Tools (utilities NEO can call)

- **delegation-scoring-matrix** — When you ask NEO to do 5 things at once, this picks which to do first
- **language-selection-matrix** — Picks the best AI provider for each task (DeepSeek for code, Grok for real-time, etc.)
- **neo-build-orchestrator** — Runs multi-step build pipelines

### Personality

- **NEO Agent 2** by default — friendly, direct, helpful
- Change to any name and tone in the `.env` file
- Full custom personality: drop a `personality.md` in `%LOCALAPPDATA%\hermes\`

---

## Need help?

- **Telegram support** — message the bot that came with your purchase (Pro Skills Bundle customers only)
- **Email** — support@neo-lite.example
- **Discord** — coming soon
- **GitHub issues** — https://github.com/willoh13/neo-lite/issues

**Common fix time:** 90% of issues are fixed by restarting the gateway (`hermes gateway restart`) or re-checking the `.env` file for typos.

---

## What this guide does NOT do (yet)

- **Google OAuth** — to read your email/calendar, you need to set up Google API access separately. Guide coming in v1.1.
- **Voice mode** — talking to NEO with your voice. Roadmap Q4 2026.
- **Desktop GUI** — a native Windows app instead of Telegram. Roadmap Q1 2027.
- **Multi-user mode** — letting teammates use your NEO. Pro tier, roadmap TBD.

If you need any of these now, the White-Glove install ($2,499) includes custom setup.

---

**Version:** 1.0.0
**Last updated:** 2026-07-15
**Tested on:** Windows 11 Home, Windows 11 Pro, Windows 10 22H2
**Hermes Agent version:** 0.17.0+
