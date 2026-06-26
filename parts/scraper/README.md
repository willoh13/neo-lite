# ─── NEO-Scraper Part Installation Guide ────────────────────────────────────
#
# This adds website crawling capability to NEO Core.
# Your customer needs:
#   1. NEO Core running (Docker)
#   2. This part folder
#   3. 2 minutes for setup

## Quick Install (one command)

```bash
# From the NEO Core directory:
cp -r parts/scraper skills/scraper
pip install -r parts/scraper/requirements-scraper.txt
playwright install chromium
docker compose restart
```

Then test with:
```bash
python3 skills/scraper/scraper.py "https://example.com" --output test-crawl.md
```

## Getting Better Results

After your first test run, check out the **Agent Workflow Review Guide** (`getting-better-results.md` — included next to this README). It walks you through a simple 5-minute review loop to turn mediocre scrapes into repeatable good ones. Ask yourself:

- What was useful about the output?
- What was wrong or missing?
- What one fix would make the next run better?

Track 3 runs, make one improvement each time, and decide if the workflow is worth saving for daily use.

## What to email the customer
Attach the entire `parts/scraper/` folder as a zip. Tell them:

> "NEO-Scraper adds web crawling to your NEO. Unzip, then run:
> - `pip install -r requirements-scraper.txt`
> - `playwright install chromium`
> - `cp -r scraper skills/`
> - `python3 scraper/scraper.py 'https://your-url-here.com' --output results.md`
>
> No API needed — it uses your existing DeepSeek setup."
