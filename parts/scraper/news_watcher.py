#!/usr/bin/env python3
"""
NEO News Watcher — Cron-ready AI news scraper.

Uses NEO-Scraper to monitor AI news sources daily.
Outputs a clean briefing to your terminal.

Customize the SOURCES list for your niche.
"""
import asyncio
import json
import os
import sys
from datetime import datetime

# ============================================================
# 🔧 CUSTOMIZE YOUR SOURCES HERE
# ============================================================
# Add, remove, or reorder URLs you want to monitor.

SOURCES = [
    # AI News (daily)
    "https://www.theverge.com/ai-artificial-intelligence",
    "https://techcrunch.com/category/artificial-intelligence/",
    "https://arstechnica.com/ai/",
    "https://venturebeat.com/category/ai/",

    # AI Research
    "https://www.artificialintelligence-news.com/",
    "https://www.technologyreview.com/topic/artificial-intelligence/",

    # Robotics
    "https://spectrum.ieee.org/topic/robotics/",
]

# Keywords to highlight in results
KEYWORDS = [
    "lawsuit", "lawsuits", "SEC", "FTC", "regulation", "ban",
    "breakthrough", "AGI", "open source", "Claude", "GPT", "Gemini",
    "robot", "humanoid", "autonomous",
]


async def run():
    """Import scraper and crawl sources."""
    sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "scraper"))
    from scraper import crawl_single

    print(f"=== NEO News Watcher — {datetime.now().strftime('%Y-%m-%d %H:%M')} ===\n")

    for url in SOURCES:
        print(f"📡 {url}")
        result = await crawl_single(url, timeout=20)
        if result["success"]:
            content = result.get("content", "")
            matches = []
            for kw in KEYWORDS:
                if kw.lower() in content.lower():
                    matches.append(kw)
            if matches:
                print(f"   ✅ {len(content)} chars — Keywords found: {', '.join(matches)}")
            else:
                print(f"   ✅ {len(content)} chars (no keyword matches today)")
        else:
            print(f"   ❌ Failed: {result.get('error', 'unknown')}")
        print()

    print("=== Done ===")


if __name__ == "__main__":
    asyncio.run(run())
