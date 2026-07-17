# NEO Operator Desktop — Tier 3 Concept

> "The first JARVIS you actually own — and you can see its brain grow."

This is a vision doc for the v3 desktop app, **not a build plan**. The actual
implementation work happens after v1 (Telegram + CLI) and v2 (web UI) ship.

---

## 1. What you're looking at

Open `index.html` next to this file in any browser. That's the high-fidelity
mockup of what the Tauri/Electron app would feel like in day-to-day use.

**Two views, one app:**

### Chat view (default)

Three-pane layout:

- **Left rail (60px):** icon shortcuts — Chat, **JARVIS HUD**, Files, Schedule, Skills, Memory, Logs
- **Sidebar (240px):** conversation history, searchable, grouped by Today / Yesterday / This week
- **Chat (flex):** the actual conversation with NEO, markdown, code blocks, tool calls
- **Right pane (320px):** **the Brain** — live view of what NEO is thinking about, what files it has open, what it remembers, and what skills it just used

### JARVIS HUD view (the cinematic one)

Click the 🛰️ icon in the left rail to swap the right pane for a full
Iron-Man-style holographic display. Canvas-animated, GPU-rendered at 60fps.

**What it does:**

- **Concentric rings** that pulse outward when you speak, breathe when idle
- **Central glowing core** that brightens and grows with audio amplitude
- **Memory constellation** — 147 small dots representing your vault files, drifting in a slow orbit. Brighter dots are more-frequently-accessed memories.
- **5 active context nodes** (green, labeled: Q3, Notion, Voice, Cron, Stack) — these are the files/tools NEO is currently reasoning about
- **Voice waveform** appears at the bottom when listening mode is active
- **4 mode toggles** (IDLE / LISTEN / THINK / GROW) that change the entire mood of the visualization

**4 modes you can try right now** (click the buttons at the top of the HUD):

| Mode | What it shows | Vibe |
|---|---|---|
| **IDLE** | Slow breathing pulse, dim ambient glow | "Good afternoon, Will. 147 memories indexed. Ready when you are." |
| **LISTEN** | Bright rings expanding outward, waveform at the bottom, faster orbit | "Speak now. I'm listening." |
| **THINK** | Medium pulse, faster node orbit, nodes connect to center | "Querying Notion, 3 memories, brand voice…" |
| **GROW** | New nodes spawn from the outside and drift inward, slow dramatic pulse | "Adding new memory: 'Q3 standup prep = weekly recurring'" |

**Side panels** (always visible, regardless of mode):
- **Left:** ACTIVE CONTEXT — current files/tools in working memory
- **Right:** RECENT MEMORIES — count totals, today's growth, vault size
- **Corners:** SYS status, cognitive load %, uptime, NEO version + memory count

**How to use it:**

1. Open `index.html` in a browser
2. Click the 🛰️ icon in the left rail
3. Click the **LISTEN** button to see the "speaking" state
4. Click the **GROW** button to watch memories form
5. Hit the 🎤 **HOLD TO SPEAK** button to toggle listening manually

**Screenshots of each mode:**

- `preview-hud-listening.png` — the "speaking" state
- `preview-hud-thinking.png` — the "processing" state
- `preview-hud-growing.png` — the "learning" state
- `preview.png` — the original chat view (right panel = Brain)

---

## 2. The "brain growing" idea (the part Will asked about)

The right panel is the differentiator. Two things make it special:

### (a) Live context — see what NEO is reading right now

When NEO reads a file, queries Notion, runs a command — you see it in real
time. Not "I checked your Notion" — you see the file name, the size, and the
last access time. **No more "did it actually do it?"** The same verification
discipline that produces the "Brain grew today: +3 notes" banner.

### (b) Obsidian vault as the memory substrate

This is the key idea: **NEO's "memory" is just a folder of markdown files
on your disk.** Specifically, an Obsidian vault.

```
~/NEO-Brain/                       ← your Obsidian vault root
├── 0-Inbox/                       ← raw notes, gets sorted weekly
├── 1-Projects/                    ← active projects
│   ├── Q3 content calendar.md
│   ├── NEO Operator launch.md
│   └── Daily AI briefing.md
├── 2-Areas/                       ← ongoing responsibilities
│   ├── Health.md
│   ├── Family.md
│   └── Businesses.md
├── 3-Resources/                   ← reference material
│   ├── NEO_STACK.md
│   ├── Brand voice.md
│   └── API costs.md
├── 4-Archives/                    ← completed work
└── .neo/                          ← system-managed (hidden in Obsidian)
    ├── memory.jsonl               ← long-term facts about Will
    ├── session-log/               ← one file per conversation
    └── skills/                    ← skill definitions
```

**Why this is the right call:**

1. **You can read the brain yourself.** Open the vault in Obsidian, browse
   the markdown, search it with Ctrl+F. No proprietary memory format, no
   "where does the AI keep its notes?" mystery.

2. **You can edit the brain.** If NEO remembers something wrong, just open
   the file and fix it. Next conversation picks up the correction.

3. **You can back it up.** It's a folder. Put it in Git, Backblaze, Dropbox,
   whatever. Standard file backup, no special tooling.

4. **You can port it.** Move to a new machine? Copy the folder. Switch
   from NEO to a different AI? The notes are still useful to you as a human.

5. **The graph is the bonus.** Obsidian's killer feature is the backlinking
   graph. As NEO works, every note it touches gets a `[[wikilink]]` to
   related notes. Over time, the vault becomes a *real knowledge graph* of
   your life and work. You can see clusters form, see what topics are
   connected, see where the gaps are.

### How NEO writes to the vault

When the desktop app is open, NEO's tools include a `vault` toolset:

- `vault_read(path)` — read a file
- `vault_write(path, content)` — create or overwrite
- `vault_append(path, content)` — append to a daily log
- `vault_search(query)` — full-text search
- `vault_link(from, to)` — add a `[[wikilink]]` between two notes
- `vault_move(from, to)` — reorganize (PARA method)
- `vault_today()` — append to today's daily note

When the app is closed, these tools are unavailable — NEO falls back to its
built-in JSONL memory. So you can keep using NEO Operator via Telegram or CLI
without Obsidian; the desktop app just unlocks the deeper integration.

### The "brain growing" feedback loop

The right panel shows growth in real time. Every time NEO:

- Adds a new long-term fact → "Memories: 147 → 148"
- Creates a new project note → "📂 1-Projects now has 12 notes (was 11)"
- Adds a backlink → "🔗 Brand voice.md now linked from 4 notes (was 3)"
- Runs a skill → "⚡ Skills used today: 7 (was 6)"

You watch the brain *actually grow*. Over months, the count of notes,
memories, and connections becomes a quiet status symbol of your
collaboration with your AI.

---

## 3. Tech stack

**Tauri** (Rust core, system webview for UI), not Electron. Reasons:

| | Tauri | Electron |
|---|---|---|
| Binary size | ~10 MB | ~150 MB |
| Memory at idle | ~30 MB | ~200 MB |
| Startup time | <1s | 2-4s |
| Native feel | Better (uses OS webview) | Worse (ships Chromium) |
| Build complexity | Higher (Rust toolchain) | Lower (just JS) |
| Cross-platform | ✅ Mac/Win/Linux | ✅ Mac/Win/Linux |

The 5x smaller footprint matters when NEO Operator's whole pitch is "runs on a
$300 Minisforum." Bundling a 150MB Electron runtime contradicts that.

**Frontend:** Vanilla HTML/CSS/JS for v1 of the desktop app. No React, no
build pipeline. The mockup in `index.html` is 90% of the way to a working
app — Tauri just wraps it in a system webview and exposes the filesystem
and vault tools via a small Rust backend.

**Tauri plugins used:**

- `tauri-plugin-fs` — file access (sandboxed to the vault folder)
- `tauri-plugin-shell` — open external links (e.g., open file in Obsidian)
- `tauri-plugin-updater` — auto-update the desktop app
- `tauri-plugin-notification` — system notifications for cron jobs
- `tauri-plugin-global-shortcut` — global hotkey to summon NEO (⌘Space)

---

## 4. Build effort estimate

| Phase | Time | Deliverable |
|---|---|---|
| **Spec** | ✅ Done | This doc + mockup |
| **Tauri scaffold** | 2 days | Hello-world Tauri app wrapping the HTML |
| **Vault toolset** | 1 week | Rust commands exposing vault_read/write/etc to the agent |
| **Live context panel** | 3 days | WebSocket from agent → frontend showing real-time state |
| **Brain growth tracking** | 2 days | Diff the vault on every write, show "X changed" |
| **Global hotkey + tray** | 2 days | ⌘Space summon, system tray icon (one of the 6 SVG avatars) |
| **Packaging + auto-update** | 3 days | Signed Mac/Windows/Linux installers, update channel |
| **Beta with 5 users** | 2 weeks | Real-world testing |
| **Public release** | 1 day | Announce, push to website, social |

**Total: ~6 weeks** for one developer (Will + NEO working together).

---

## 5. When to build this

**Not now.** v1 (Telegram + CLI) ships first. v2 (web UI) ships second.
The desktop app is the v3 differentiator — the thing that makes NEO Operator
*better than a Telegram bot with a personality*.

Build order:

1. **v1 (now → 2 weeks):** Docker install + Telegram + CLI. Get 10 users.
2. **v2 (1 month):** Web UI. Get 50 users. License keys start working.
3. **v3 (3 months):** Desktop app + Obsidian integration. This becomes
   the headline feature of "NEO Pro" tier. Pricing: $20/mo or $200/yr.

---

## 6. Open questions for Will

- [ ] **Vault location:** `~/NEO-Brain/`? Or ask user during install wizard?
- [ ] **Obsidian requirement:** does the user HAVE to use Obsidian, or can
      the desktop app work with any folder of markdown files? (My pick:
      any folder. Obsidian is a bonus, not a requirement.)
- [ ] **Privacy boundary:** vault files contain everything NEO knows. Do
      we encrypt at rest? (My pick: no, it's a folder on the user's disk.
      Same trust model as any notes app.)
- [ ] **Multi-vault support:** power users might want one vault per project.
      (My pick: yes, but v3 — not v1.)
- [ ] **Memory format:** JSONL for facts, markdown for context. Or all
      markdown with frontmatter? (My pick: all markdown. More human-readable,
      no special tooling needed.)

---

## 7. How to view this mockup

```bash
# Just open it
open /home/neoagent/neo-operator/assets/desktop-mockup/index.html

# Or host it locally if you want to share
cd /home/neoagent/neo-operator/assets/desktop-mockup
python3 -m http.server 8000
# → http://localhost:8000
```

The HTML is fully self-contained. No CDN, no external assets. You can
email it, share it, open it on any device with a browser.

---

**Bottom line:** Tier 3 is the "JARVIS on your desktop" moment. The Obsidian
integration is what makes it feel like NEO is *yours* — not a chatbot, but
a real partner with a memory you can see, read, and edit. That's the v3
pitch. Don't build it until v1 and v2 are paying customers.
