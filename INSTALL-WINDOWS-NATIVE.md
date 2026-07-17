# NEO Operator for Windows — Customer Install Guide
## The 10-Minute Install (No Docker, No WSL, No Linux)

This guide installs **NEO Agent 2** — your personal AI chief of staff — on Windows 10 or 11. It uses the official Hermes Agent installer and adds the NEO personality layer, the full Skills Bundle, and your Telegram bot. Everything is one Python install, no virtual machines, no containers.

**Total install time: 10-20 minutes on a clean machine.** Most of that is downloading Python, Git, and Node — the actual NEO setup is fast.

> **Important:** Ignore any file called `install-windows.bat` in your Downloads folder. That's the old Docker-based installer. This guide does NOT use Docker. If a customer service rep tells you to run that file, they're out of date — point them to this guide.

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
6. **A Google Gemini API key** (free tier) — multimodal AI. Get one: https://aistudio.google.com/apikey

You can add more AI providers later. NEO picks the best one for each task automatically.

---

## Part 1 — Install NEO Operator (the actual install)

This part has two phases. **Phase 1 installs Hermes** (the AI runtime — the foundation). **Phase 2 adds NEO on top** (personality, skills, your Telegram bot). Don't skip Phase 1.

### Step 1.1: Open PowerShell as Administrator

- Press the **Windows key** (or click the Start button)
- Type `powershell` (on Windows 10) or `terminal` (on Windows 11)
- Right-click **"Windows PowerShell"** or **"Terminal"**
- Choose **"Run as administrator"**
- Click **Yes** when Windows asks if you're sure

You should see a PowerShell window. The title bar will say "Administrator".

### Step 1.2: Allow script execution (one-time)

Copy and paste this line into PowerShell, then press **Enter**:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

If it doesn't print anything, that's fine. If it asks for confirmation, type `Y` and press Enter.

---

## Phase 1: Install Hermes Agent (the foundation)

Hermes is the AI runtime — the part that actually runs the AI and talks to Telegram. NEO is the personality layer on top. Install Hermes first, then add NEO.

### Step 1.3: Install Hermes Agent

Paste and Enter:

```powershell
iex (irm https://hermes-agent.nousresearch.com/install.ps1)
```

This will:
- Download a small Python tool called `uv` (fast Python package manager)
- Download Python, Git, and Node if you don't have them
- Download Hermes Agent (about 50 MB)
- Install it to `%LOCALAPPDATA%\hermes\`
- Add `hermes` to your PATH

**Watch for these prompts:**

1. **"Hermes was installed successfully"** — good, press Enter
2. **A question about which AI provider to use** — choose **DeepSeek** (it's the first or second option, depending on the menu). If you're not sure, pick DeepSeek — you can add others later in Part 2.
3. **"Paste your API key"** — paste your DeepSeek key, press Enter. It won't show on screen, that's normal.
4. **A question about Telegram** — say **Yes** (`Y`), then paste your bot token, press Enter, paste your user ID, press Enter.

**If you accidentally pick the wrong provider** (e.g., you choose Anthropic but don't have an Anthropic key), you can fix it later in Part 2.

When the installer closes and you're back at the prompt, **close this PowerShell window and open a new one as Administrator** (repeat Step 1.1). The PATH change only takes effect in new windows. Then verify:

```powershell
hermes --version
```

You should see something like `Hermes Agent v0.17.0`. If you see "hermes: The term 'hermes' is not recognized", try one more time: close all PowerShell windows, sign out of Windows, sign back in, open a new PowerShell as Administrator, and run `hermes --version` again.

**If the version number is BELOW v0.17.0**, your install is too old. Re-run the `iex (irm ...)` command from this step to update.

**If `hermes --version` shows v0.17.0 or higher, you're ready for Phase 2.**

---

## Phase 2: Add NEO on top of Hermes

Now that Hermes is installed and working, we add the NEO personality, the Skills Bundle, and your API keys.

### Step 1.4: Download the NEO Skills Bundle

Paste and Enter:

```powershell
$downloads = [Environment]::GetFolderPath('UserProfile') + '\Downloads'
$bundleZip = "$downloads\neo-bundle-v1.0.0.zip"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/willoh13/neo-operator/test-public-flag/dist/neo-bundle-v1.0.0.zip' -OutFile $bundleZip
Expand-Archive -Path $bundleZip -DestinationPath $downloads -Force
Get-ChildItem "$downloads\neo-bundle" -Recurse | Unblock-File

$bundleSource = "$downloads\neo-bundle"

Write-Host ""
Write-Host "Skills Bundle downloaded to: $bundleSource" -ForegroundColor Green
Write-Host ""
```

Should take 5-15 seconds. You'll see one green status line when done.

### Step 1.5: Apply the NEO personality + Skills Bundle

This copies NEO's voice, memory, skills, and tools into your Hermes install. Paste and Enter:

```powershell
$hermesHome = "$env:LOCALAPPDATA\hermes"
$bundleSource = "$downloads\neo-bundle"

# Create the destination directories (Hermes doesn't pre-create these)
New-Item -Path "$hermesHome\config", "$hermesHome\skills", "$hermesHome\tools", "$hermesHome\parts" -ItemType Directory -Force | Out-Null

# Copy NEO personality
Copy-Item -Path "$bundleSource\config\*" -Destination "$hermesHome\config\" -Recurse -Force

# Copy skills
Copy-Item -Path "$bundleSource\skills\*" -Destination "$hermesHome\skills\" -Recurse -Force

# Copy tools
Copy-Item -Path "$bundleSource\tools\*" -Destination "$hermesHome\tools\" -Recurse -Force

# Copy parts (add-on capability packs)
Copy-Item -Path "$bundleSource\parts\*" -Destination "$hermesHome\parts\" -Recurse -Force

Write-Host ""
Write-Host "NEO Agent 2 personality applied." -ForegroundColor Green
Write-Host "Skills Bundle installed (2 parts, 2 skills, 3 tools)." -ForegroundColor Green
Write-Host ""
```

You should see two green status lines. If you see red error text, paste the exact error in your support channel.

### Step 1.6: Create your .env file

NEO needs to know your API keys and Telegram bot settings. The Skills Bundle includes a `.env.example` template — we copy it to `.env` and you fill in the real values. Paste and Enter:

```powershell
$hermesHome = "$env:LOCALAPPDATA\hermes"
$bundleSource = "$downloads\neo-bundle"
$bundleEnvExample = "$bundleSource\neo-bundle\.env.example"

# Copy the template to your Hermes home
if (Test-Path $bundleEnvExample) {
    Copy-Item $bundleEnvExample "$hermesHome\.env.example" -Force
}

# Create .env from the template
if (!(Test-Path "$hermesHome\.env")) {
    if (Test-Path "$hermesHome\.env.example") {
        Copy-Item "$hermesHome\.env.example" "$hermesHome\.env"
    } else {
        # If the bundle didn't ship with .env.example, create a minimal one
        $minimalEnv = @"
# NEO Operator — minimal .env (edit the values below)
DEEPSEEK_API_KEY=
TELE...=NEO Agent 2
NEO_AI_TONE=friendly
"@
        $minimalEnv | Out-File "$hermesHome\.env" -Encoding utf8
    }
}

# Open .env in Notepad
notepad "$hermesHome\.env"
```

Notepad opens with the `.env` file. **Edit the file now:**

1. Find the line `DEEPSEEK_API_KEY=` and paste your key after the `=`. Save with **Ctrl+S**, close Notepad.
2. **If you have other API keys** (Groq, xAI, Google), find those lines too and add your keys. The file has all the lines — most are empty.
3. **If the file doesn't have a `TELEGRAM_BOT_TOKEN=` line** (some templates have it commented out with `#`), add it on a new line. Same for `TELEGRAM_ALLOWED_USERS` and `TELEGRAM_HOME_CHANNEL`.

**At minimum, the file must contain these 4 lines with real values** (no `#` in front, no empty after `=`):

```
DEEPSEEK_API_KEY=your-deepseek-key-here
TELEGRAM_BOT_TOKEN=your-bot-token-here
TELEGRAM_ALLOWED_USERS=your-telegram-user-id
TELEGRAM_HOME_CHANNEL=your-telegram-user-id
```

TELEGRAM_ALLOWED_USERS=your-telegram-user-id
TELEGRAM_HOME_CHANNEL=your-telegram-user-id
```

(Use your real Telegram user ID, not the example number.)

**Save** the file (Ctrl+S) and **close** Notepad.

### Step 1.7: Start NEO

Paste and Enter:

```powershell
hermes gateway start
```

You should see something like `Gateway started! Your bot is now online.` (the exact text varies by version).

**Verify it actually started:**

```powershell
hermes gateway status
```

You should see `Status: running` or similar. If it says `stopped`, wait 5 seconds and run `hermes gateway status` again.

**If it says "Address already in use" or "port 8080 is busy"**, another program is using port 8080. See Troubleshooting #3 below.

### Step 1.8: Talk to your bot

Before NEO can message you, you need to message it first. Telegram bots can't initiate conversations.

1. Open Telegram on your phone or desktop
2. Search for your bot's username (e.g., `NEOAgent2Bot`)
3. Send it a message: `/start`
4. Wait 2-3 seconds
5. Send another message: `hello, are you alive?`

**Within 5-10 seconds, your bot should reply.** If it does, congratulations — NEO is installed and working.

**If the bot doesn't reply:**

1. Check the logs: `hermes logs --tail 50` — look for red error lines
2. Most common issue: the `.env` file is missing one of the 4 required keys (Step 1.6)
3. Verify your bot token: message @BotFather on Telegram, send `/token`, pick your bot, it shows the token
4. Verify your user ID: message @userinfobot on Telegram again

---

## Part 2 — Add more AI providers (optional)

NEO works great with just DeepSeek, but adding more providers makes it smarter and gives you fallbacks. If you're happy with DeepSeek, skip this part.

### Step 2.1: Open the .env file again

```powershell
notepad "$env:LOCALAPPDATA\hermes\.env"
```

### Step 2.2: Add your keys

For each AI provider you have, find the line and add your key. For example:

```
DEEPSEEK_API_KEY=your-deepseek-key-here
X...Save (Ctrl+S) and close Notepad.

### Step 2.3: Restart NEO

```powershell
hermes gateway stop
hermes gateway start
```

Wait 5 seconds, then test in Telegram again. NEO will now use the new providers for tasks where they're better than DeepSeek.

### Step 2.4: Verify the new provider is being used

In Telegram, message your bot:

```
what AI providers are you using?
```

It should list the ones you configured.

---

## Part 3 — Daily use

### Starting NEO

NEO starts automatically when you log into Windows. If it's not running:

```powershell
hermes gateway start
```

### Talking to NEO

Open Telegram, message your bot. Examples:

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
# Re-download the latest bundle
$latest = "$env:USERPROFILE\Downloads\neo-bundle-latest.zip"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/willoh13/neo-operator/test-public-flag/dist/neo-bundle-v1.0.0.zip' -OutFile $latest
Expand-Archive -Path $latest -DestinationPath "$env:USERPROFILE\Downloads\bundle-latest" -Force

# Re-apply (overwrites your old skills/tools/parts)
$hermesHome = "$env:LOCALAPPDATA\hermes"
$bundlePath = "$env:USERPROFILE\Downloads\bundle-latest\neo-bundle"
Copy-Item -Path "$bundlePath\skills\*" -Destination "$hermesHome\skills\" -Recurse -Force
Copy-Item -Path "$bundlePath\tools\*" -Destination "$hermesHome\tools\" -Recurse -Force
Copy-Item -Path "$bundlePath\parts\*" -Destination "$hermesHome\parts\" -Recurse -Force

# Restart
hermes gateway restart
```

---

## Part 4 — Troubleshooting

### 1. "hermes: The term 'hermes' is not recognized"

PATH isn't updated yet. Try in order:
1. Close PowerShell, open a new one as Administrator, try again
2. Sign out of Windows, sign back in, try again
3. Restart Windows, try again

### 2. NEO doesn't reply in Telegram

1. Make sure you sent `/start` to the bot FIRST (Step 1.8). Telegram bots can't initiate conversations.
2. Check the gateway is running: `hermes gateway status`
3. If "stopped", start it: `hermes gateway start`
4. Check the logs: `hermes logs --tail 50` — look for red error lines
5. Most common cause: `.env` file is missing one of the 4 required keys (Step 1.6). Open the file and verify all 4 lines have real values, no `#` in front.
6. Verify your bot token: message @BotFather on Telegram, send `/token`, pick your bot, it shows the token. Compare to what's in your `.env`.
7. Verify your user ID: message @userinfobot on Telegram again.

### 3. "Address already in use" or "port 8080 is busy"

Another program is using port 8080. Common culprits: Skype, IIS, another Docker container. To find and kill it:

```powershell
netstat -ano | findstr :8080
# Find the PID (last column), then:
taskkill /PID <the-number> /F
```

Or just change NEO's port by editing `%LOCALAPPDATA%\hermes\config\config.yaml` and changing `port: 8080` to `port: 8081`. Then restart the gateway.

### 4. NEO replies but with weird/wrong answers

1. Check the logs: `hermes logs --tail 50` — look for "API key invalid" or "rate limit" errors
2. If "API key invalid", your DeepSeek key is wrong. Get a new one at https://platform.deepseek.com/api_keys
3. If "rate limit", you've hit DeepSeek's free tier cap. Wait an hour, or add a Groq key (Part 2)

### 5. Install fails partway through

The Hermes installer creates a log:

```powershell
Get-Content "$env:LOCALAPPDATA\hermes\install.log" -Tail 50
```

Paste the output in your support channel.

### 6. Reset everything and start over

```powershell
hermes gateway stop
hermes uninstall
# Then re-run Part 1 from Step 1.4
```

---

## Part 5 — What's included in the Skills Bundle

This is what you get with NEO Operator (free) and the Pro Skills Bundle ($79). Everything in the bundle is included in the install above.

### Add-on Parts (capability packs)

- **scraper** — Turn any website into structured data. News sites, real estate listings, job boards, you name it.
- **support-agent** — A second AI that helps your customers install and use NEO. Useful if you're reselling.

### Skills (workflows NEO knows how to run)

- **neo-operator-planner** — Breaks big goals into step-by-step plans
- **neo-operator-researcher** — Multi-source research with citations

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
- **Email** — support@neo-operator.example
- **Discord** — coming soon
- **GitHub issues** — https://github.com/willoh13/neo-operator/issues

**Common fix time:** 90% of issues are fixed by restarting the gateway (`hermes gateway restart`) or re-checking the `.env` file for typos.

---

## What this guide does NOT do (yet)

- **Google OAuth** — to read your email/calendar, you need to set up Google API access separately. Guide coming in v1.1.
- **Voice mode** — talking to NEO with your voice. Roadmap Q4 2026.
- **Desktop GUI** — a native Windows app instead of Telegram. Roadmap Q1 2027.
- **Multi-user mode** — letting teammates use your NEO. Pro tier, roadmap TBD.

If you need any of these now, the White-Glove install ($2,499) includes custom setup.

---

**Version:** 1.0.2
**Last updated:** 2026-07-15
**Hermes Agent version required:** 0.17.0+
**Tested on:** Windows 11 Home, Windows 11 Pro, Windows 10 22H2 (after bug-fix pass)
