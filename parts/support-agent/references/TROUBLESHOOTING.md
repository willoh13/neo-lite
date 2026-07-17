# NEO Operator Troubleshooting FAQ

Read this **before** attempting any fix. If the issue isn't here, try to fix it once. If your fix doesn't work, escalate.

Each entry has: **Symptom** → **Cause (90% of the time)** → **Fix** → **If that doesn't work, escalate**.

---

## 1. Bot not responding to messages

**Symptom:** Customer sends a message to their bot, no reply (or reply comes 30+ seconds late).

**Cause:** Almost always one of:
- Telegram bot token wrong / has trailing space / got reset
- Container not actually running
- Wrong chat ID in `TELEGRAM_ALLOWED_CHAT_IDS`

**Fix:**
```
1. docker compose ps          # is neo-operator running?
2. docker compose logs --tail=50 neo-operator  # any errors?
3. cat .env | grep TELEGRAM   # is the token in there?
4. Ask customer to message @userinfobot — confirm the user ID matches .env
```

**If none of that:** escalate. Could be Telegram API outage (rare), could be customer is messaging a *different* bot than they think.

---

## 2. "Invalid API key" errors

**Symptom:** Customer says NEO is replying but the reply is "I'm sorry, I encountered an error" or similar.

**Cause:** API key is wrong, expired, or has a billing issue.

**Fix:**
1. Ask customer to test the key directly: `curl -H "Authorization: Bearer $OPENAI_API_KEY" https://api.openai.com/v1/models` (or equivalent for their provider)
2. If it returns 401: key is wrong, ask them to regenerate
3. If it returns 200: key is fine, the issue is in the NEO config — escalate

**OpenAI-specific:** tell them to check https://platform.openai.com/usage — sometimes they hit a hard cap and need to add credits.

**DeepSeek-specific:** DeepSeek has occasional regional rate limit issues. Tell customer to wait 5 min and retry.

---

## 3. Wizard keeps asking questions every restart

**Symptom:** Customer says the wizard runs every time the container starts.

**Cause:** `.onboarded` file isn't persisting. Either the volume mount is wrong, or they ran `docker compose down -v` (the `-v` deletes volumes).

**Fix:**
1. Check `docker compose ps # is neo-operator running-data` volume is mounted
2. Check `ls -la ~/.hermes/.onboarded` (inside the container: `docker compose exec neo-operator ls -la /root/.hermes/.onboarded`)
3. If the file isn't there, run the wizard one more time, then `docker compose restart` (NOT `down -v`)

**If they ran `docker compose down -v`:** they nuked their config. Walk them through re-onboarding. Lesson learned.

---

## 4. Out of memory / container killed

**Symptom:** Customer says NEO stopped responding, container is restarting repeatedly, `docker compose ps` shows "Restarting".

**Cause:** RAM exhausted. The model (especially local Ollama) is using more memory than the container limit allows.

**Fix:**
1. `docker stats neo-operator` — see actual memory usage
2. If they're using local Ollama, recommend a smaller model: `ollama pull llama3.1:8b` instead of `qwen2.5:14b`
3. Bump `NEO_MEM_LIMIT` in `.env` (e.g., from `1g` to `4g`) and restart
4. If they have 8GB or less total RAM, they CANNOT run a 14B model — they need 8B or smaller

**If they insist on running a model their hardware can't handle:** don't fight it. Recommend a cloud provider (DeepSeek is cheapest) and use that.

---

## 5. "My AI forgot everything"

**Symptom:** Customer says NEO doesn't remember things they told it yesterday.

**Cause:** Memory persistence issue. Either:
- `neo-operator-data` volume was deleted
- The conversation was in a Telegram topic that got archived
- Customer is messaging a *different bot* than the one that had the memory

**Fix:**
1. `docker compose exec neo-operator ls /root/.hermes/memory/` — should have files
2. If empty: memory was wiped, escalate (this is a data loss issue, Will should respond)
3. If non-empty: ask customer which bot they're messaging. If it's a new bot, the memory is on the old one.

**Important:** don't promise that lost memory can be recovered. NEO's memory files are JSON, *if* they have a backup, we can restore. Otherwise it's gone.

---

## 6. Telegram bot token "Unauthorized" error

**Symptom:** `docker compose logs` shows `telegram: 401 Unauthorized` repeatedly.

**Cause:** Token is wrong, or customer regenerated the token in BotFather and forgot to update `.env`.

**Fix:**
1. Ask customer to check BotFather for their current token
2. Compare to what's in `.env`
3. If different, update `.env` and `docker compose restart`

---

## 7. Ollama not reachable from inside the container

**Symptom:** Customer says "I'm running Ollama locally but NEO says no models are available."

**Cause:** Docker can't reach the host's Ollama. Almost always the URL is wrong.

**Fix:**
1. On the host: `curl http://localhost:11434/api/tags` — should return JSON
2. In `.env`, `OLLAMA_BASE_URL` should be `http://host.docker.internal:11434/v1` (Docker Desktop) or `http://172.17.0.1:11434/v1` (Linux Docker)
3. If on Linux, also: `sudo ufw allow from 172.17.0.0/16 to any port 11434` (firewall)

**If still not working:** tell customer to run Ollama with `OLLAMA_HOST=0.0.0.0` so it binds to all interfaces.

---

## 8. Wizard doesn't run / wizard runs in non-interactive mode

**Symptom:** Customer says they didn't see the wizard, or it ran with default "Operator" name.

**Cause:** They started the container detached (`docker compose up -d` without `-it`). No TTY = no wizard.

**Fix:**
1. `docker compose down`
2. `docker compose up` (without `-d`) — runs in foreground, wizard shows
3. Or: set `NEO_USER_NAME`, `NEO_USER_EMAIL`, `NEO_USER_ROLE` in `.env` and the wizard will skip with those values

**Don't tell them to use `docker attach` — it has its own issues.**

---

## 9. NEO replies but in the wrong tone / name

**Symptom:** Customer named their AI "Sage" but it's calling itself "Assistant". Or they wanted "warm" tone but it's casual.

**Cause:** `NEO_AI_NAME` / `NEO_AI_TONE` not in `.env`, or the container wasn't restarted after they added them.

**Fix:**
1. Check `.env` has `NEO_AI_NAME=Sage` and `NEO_AI_TONE=warm`
2. `docker compose restart neo-operator`
3. Wait 30s, send a new message — the new name + tone should be active

---

## 10. "I changed .env but nothing updated"

**Symptom:** Customer edited `.env` and the changes don't seem to take effect.

**Cause:** Container caches env at startup. Need to restart.

**Fix:** `docker compose restart neo-operator`. Wait 30s. Test.

**If still not updating:** `docker compose down && docker compose up -d` (full cycle, not just restart).

---

## 11. Customer wants to add a 2nd API key (e.g., they got an Anthropic key after starting with OpenAI)

**Symptom:** Customer has OpenAI working, just got an Anthropic key, wants to add it.

**Fix:**
1. `nano .env`
2. Add `ANTHROPIC_API_KEY=<their new key>`
3. Save, exit
4. `docker compose restart neo-operator`
5. NEO's router will pick the best model from what's available

---

## 12. "The web UI doesn't work"

**Symptom:** Customer goes to `http://localhost:8080` expecting a chat UI.

**Cause:** v1.0.0 of NEO Operator has NO web UI. It's Telegram / Discord / terminal only.

**Fix:**
> NEO Operator v1.0.0 doesn't have a web UI. All chat happens through Telegram, Discord, or the terminal. The web UI is on the roadmap (see `ROADMAP.md`).

**Don't tell them to clear their cache or try a different browser.** There's nothing to load. Set the expectation clearly.

---

## 13. Customer's machine is slow after installing NEO

**Symptom:** Customer's Mac/PC/Minisforum is suddenly sluggish.

**Cause:** NEO is using too much CPU/RAM. The container limit caps memory but not always CPU efficiently.

**Fix:**
1. `docker stats neo-operator` — see actual usage
2. If running a local model, recommend a smaller one
3. Set `NEO_CPUS=0.5` in `.env` to cap CPU at 50% of one core
4. If they're not using NEO actively, the container is idle — but if the issue persists, they can `docker compose stop neo-operator` to fully shut it down (and `up -d` to restart)

---

## 14. Docker permission denied errors

**Symptom:** `docker compose up` fails with "permission denied" connecting to Docker daemon.

**Cause:** Customer's user isn't in the `docker` group.

**Fix (Linux):**
```
sudo usermod -aG docker $USER
newgrp docker
docker compose up -d
```

**Fix (Mac/Windows):** Make sure Docker Desktop is running.

---

## 15. "I lost my Telegram chat ID"

**Symptom:** Customer changed phones, lost the chat ID that was in `.env`.

**Fix:**
1. Customer messages @userinfobot on Telegram — bot replies with their numeric user ID
2. Update `TELEGRAM_ALLOWED_CHAT_IDS` in `.env` with that number
3. `docker compose restart neo-operator`

---

## 16. NEO is making things up (hallucinating)

**Symptom:** Customer says NEO is inventing facts, file contents, or API endpoints.

**Cause:** Could be:
- Wrong model (using a too-cheap model for the task)
- Hallucination is just what LLMs do sometimes
- Confused context (memory is corrupted)

**Fix:**
1. Ask which model they're using. If it's `gpt-4o-mini` or `llama3.1:8b`, suggest `gpt-4o` or `claude-sonnet` for higher-stakes work
2. Ask customer to verify the claim — "Can you paste the source you found that in?"
3. If the model is being asked to do something it can't (e.g., access a private API), set expectations

**Do NOT tell the customer "NEO doesn't hallucinate."** It does. That's a known LLM behavior. The right answer is to use a better model for the task or to verify outputs.

---

## 17. Customer wants to use a custom voice / personality

**Symptom:** Customer wants a different tone than the 5 presets (casual, formal, warm, terse, sarcastic).

**Fix:**
1. Tell them to create `personality.md` in their NEO Operator folder
2. Walk them through what to put in it (any markdown describing the personality)
3. `docker compose restart neo-operator`
4. The custom voice will be used

**Reference:** the SOUL.md template that gets generated on first run — show them that as a starting point.

---

## 18. Customer wants to install on a NAS / Raspberry Pi / Mac Mini

**Symptom:** Customer doesn't have a Minisforum, has something else.

**Cause:** Different hardware, different Docker quirks.

**Fix (Raspberry Pi 4+):** Works, but ARM — only certain Ollama models run on ARM. Recommend `llama3.1:8b` and 8GB RAM minimum.

**Fix (Mac Mini M1/M2):** Works great. Use `host.docker.internal` like Mac. M-series Macs are excellent for local Ollama.

**Fix (Synology/QNAP NAS):** Works but Docker setup is different per NAS. Send customer to the Synology Container Manager docs. May need to set `host.docker.internal` differently (use the host's actual LAN IP).

**Fix (Windows):** Works, Docker Desktop. Ollama on Windows is supported now. Recommend WSL2 backend.

**If it's something weird (ChromeOS, custom embedded, etc.):** escalate. Probably not worth the support cost.

---

## 19. Customer accidentally deleted the wizard answers

**Symptom:** Customer wants to re-run the wizard because they typed their name wrong, or they want to change the AI's name.

**Fix:**
1. `docker compose exec neo-operator bash /entrypoint.sh` — re-runs the wizard
2. Or: edit `~/.hermes/user_profile.json` directly
3. Or: edit `NEO_AI_NAME` and `NEO_AI_TONE` in `.env` and restart

---

## 20. Customer wants to add a Part (skill pack)

**Symptom:** Customer wants to install the scraper or another Part.

**Fix:**
1. Walk them through `neo-parts install <part-name>`
2. Restart: `docker compose restart neo-operator`
3. Verify: ask the AI to use the new skill

**If a Part fails to install:** check the Part's `requirements-*.txt` and walk them through `pip install -r ...`

---

## When none of the above applies

If you've checked the FAQ, attempted a fix once, and it didn't work:

1. Capture: the exact error, the exact command, the customer's `docker compose logs --tail=50 neo-operator` output
2. Send to Will via the escalation template (`ESCALATION-TEMPLATE.md`)
3. Tell the customer: "I've handed this off to Will, he'll be in touch in the next few hours"

**Do NOT keep trying random fixes.** The customer is paying for Will's time on the hard stuff. Use it.

---

## What the FAQ doesn't cover (yet)

- Multi-user setups (multiple Telegram users on one bot)
- Custom model fine-tuning
- Production deployment (load balancers, multiple containers)
- Voice cloning (separate TTS setup)
- Mobile app integration

These are out of scope for the white-glove install. If a customer asks, say "that's a future offering" and note it in the session log so Will knows what people are asking for.
