---
name: neo-scraper
description: Website crawling and extraction for research. Crawls web pages and returns clean markdown. Supports single URLs, batch crawling from files, and scheduled scraping cron jobs.
version: 1.0.0
author: NEO
category: autonomous-ai-agents
---

# NEO-Scraper 🔍

## Overview
Web scraping skill for NEO Lite. Extracts clean text from any web page — removes ads, navigation, popups. Output is LLM-ready markdown.

## Installation
This skill is a **NEO Part** — it layers on top of NEO Core:

```bash
# 1. Stop NEO Lite if running
docker compose down

# 2. Copy the scraper part into place
cp -r parts/scraper/ skills/scraper/
cp parts/scraper/requirements-scraper.txt requirements-scraper.txt

# 3. Install dependencies
pip install -r requirements-scraper.txt
playwright install chromium

# 4. Restart
docker compose up -d
```

## Usage

### Single URL
```bash
python3 skills/scraper/scraper.py "https://example.com/article"
```

### Extract to file
```bash
python3 skills/scraper/scraper.py "https://example.com" --output research/article.md
```

### Batch crawl (multiple URLs)
Create a file `urls.txt` with one URL per line, then:
```bash
python3 skills/scraper/scraper.py --input urls.txt --output batch-results.md
```

### JSON output (for programmatic use)
```bash
python3 skills/scraper/scraper.py "https://example.com" --format json
```

### Full content (no truncation)
```bash
python3 skills/scraper/scraper.py "https://example.com/long-article" --full --output full-article.md
```

## Scheduled Crawling (Cron)
Set up a recurring crawl to monitor a page for changes:

```bash
# Crawl every morning at 6am
hermes cron create --name "Daily Tech News" \
  --schedule "0 6 * * *" \
  --prompt "Run NEO-Scraper on https://news.ycombinator.com and https://techcrunch.com --output ~/research/daily-brief.md. Summarize the top 5 stories." \
  --skills neo-scraper
```

## Configuration
| Env Variable | Default | Description |
|-------------|---------|-------------|
| `SCRAPER_TIMEOUT` | 30 | Timeout per URL in seconds |
| `SCRAPER_OUTPUT_DIR` | `~/crawls` | Default output directory |

## What It Scrapes
- ✅ Blog posts and articles
- ✅ Documentation pages
- ✅ News sites
- ✅ Landing pages
- ✅ GitHub READMEs
- ❌ PDFs, images, binary files
- ❌ Localhost/internal addresses
- ❌ Login-walled/paywalled content (only what's publicly accessible)
