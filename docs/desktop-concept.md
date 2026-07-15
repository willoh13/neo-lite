# NEO Desktop — Tier 3 Concept

> **Status:** Concept. Not started. Would ship v3+ if Tier 2 succeeds.

## The window

A floating, borderless chat window that lives in the corner of your screen.
Always there. Always listening (optional). Never in the way.

```
┌─────────────────────────────────────────────────┐
│ ◉ Atlas                              ─  □  ×    │  ← Title bar
├─────────────────────────────────────────────────┤
│                                                 │
│              [Cyan glow ring]                   │  ← JARVIS orb, animated
│                                                 │
│   ┌───────────────────────────────────────┐     │
│   │ You                                  │     │
│   │ What's on my calendar today?         │     │
│   └───────────────────────────────────────┘     │
│                                                 │
│   ┌───────────────────────────────────────┐     │
│   │ Atlas                                │     │
│   │ 3 meetings. First at 9am with Dan —  │     │
│   │ breakfast, so casual. Then a call    │     │
│   │ with Jeff at 11. Then open afternoon.│     │
│   │                                       │     │
│   │ Want me to draft a 9am prep note?    │     │
│   └───────────────────────────────────────┘     │
│                                                 │
│   ┌─────────────────────────────────────┐  ┌─┐  │
│   │ Ask Atlas anything...               │  │▶│  │
│   └─────────────────────────────────────┘  └─┘  │
│                                                 │
│         ⌥K to focus  ·  ⌘⇧A to hide  ·  🎙 mic │
└─────────────────────────────────────────────────┘
```

## Key features

- **Always-on-top mode** — pin it above other windows
- **System tray icon** — click to summon, double-click for full app
- **Global hotkey** — `⌥Space` (or `Win+Space`) to summon from anywhere
- **Voice in/out** — push-to-talk or always-listening, TTS replies
- **File peek** — drag a file onto the window, Atlas reads it
- **Quick actions** — buttons for "summarize clipboard", "schedule this", "email Dan about this"
- **Themes** — JARVIS (cyan), Friday (purple), S.A.L.T. (amber), custom CSS

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Shell | **Tauri** | Rust backend, native window, ~10MB binary vs Electron's 150MB |
| UI | **Svelte + TypeScript** | Fast, small, modern |
| IPC | **Tauri commands** | Type-safe, no need to expose Node |
| Local LLM option | **llama.cpp via Rust bindings** | True offline mode |
| Voice | **whisper.cpp** for STT, **piper** for TTS | Both run locally, free |

## Why not Electron?

- 10x bigger binary
- Slower startup (V8 spin-up)
- Worse battery life on laptops
- Less "feels like a real app"

## Why not just a web app?

- A web app lives in a tab. You close it. You forget.
- A desktop app lives in your menu bar, like 1Password or Raycast.
- The "always-available AI" pitch only works if it's actually always there.

## Effort estimate

| Phase | Time | Result |
|---|---|---|
| Phase 1: Floating chat window | 2-3 weeks | Same as the web UI but pinned |
| Phase 2: Tauri shell + system tray | 1-2 weeks | Feels like a real app |
| Phase 3: Voice in/out | 2-3 weeks | "Hey Atlas" wake word, push-to-talk |
| Phase 4: Local LLM mode | 2-3 weeks | Fully offline |
| **Total** | **8-12 weeks** | The full JARVIS experience |

## What it would feel like

Press `⌥Space` anywhere. A cyan-bordered window slides up from the bottom of
your screen. A small dot pulses. You speak: *"Atlas, schedule a call with Dan
for tomorrow at 3."* Atlas replies in a natural voice: *"Done. Calendar invite
sent to dan@. Anything else?"* You press `Esc` to dismiss. The window slides
back down. You keep typing your email.

That's the vision. Not for v1, not for v2. But it's what we're building
toward.
