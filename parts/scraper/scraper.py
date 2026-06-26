#!/usr/bin/env python3
"""
NEO-Scraper — Website extraction tool for NEO Lite.

Ships as part of the NEO-Scraper skill pack.
Crawls web pages and returns clean markdown for LLM consumption.

Usage:
    python3 scraper.py <url> [--output <path>] [--format json]
    python3 scraper.py --multi urls.txt (batch crawl from file)
"""
import argparse
import asyncio
import json
import os
import sys
import re
from urllib.parse import urlparse

# Ensure crawl4ai can find Chromium — auto-detect from common paths
COMMON_BROWSER_PATHS = [
    "/home/neoagent/.cache/ms-playwright",
    "/root/.cache/ms-playwright",
    os.path.expanduser("~/.cache/ms-playwright"),
]
for _p in COMMON_BROWSER_PATHS:
    if os.path.isdir(_p):
        os.environ.setdefault("PLAYWRIGHT_BROWSERS_PATH", _p)
        break


async def crawl_single(url: str, full: bool = False, timeout: int = 30) -> dict:
    """Crawl a single URL and return markdown."""
    try:
        from crawl4ai import AsyncWebCrawler
        from crawl4ai.async_configs import BrowserConfig, CrawlerRunConfig

        browser_config = BrowserConfig(
            browser_type="chromium",
            headless=True,
            verbose=False,
            text_mode=True,
        )

        run_config = CrawlerRunConfig(
            word_count_threshold=10 if not full else 0,
            remove_overlay_elements=True,
            exclude_social_media_links=True,
            exclude_external_links=not full,
            verbose=False,
            cache_mode="BYPASS",
        )

        async with AsyncWebCrawler(config=browser_config) as crawler:
            result = await crawler.arun(url=url, config=run_config)

            content = result.markdown or result.extracted_content or ""
            title = result.metadata.get("title", "") if result.metadata else ""

            # Truncate very long content
            max_chars = 50000 if full else 15000
            truncated = False
            if len(content) > max_chars:
                content = content[:max_chars] + "\n\n[...truncated...]"
                truncated = True

            return {
                "success": result.success,
                "url": url,
                "title": title,
                "content": content,
                "content_length": len(content),
                "truncated": truncated,
                "error": result.error_message if not result.success else None,
            }
    except ImportError as e:
        return {"success": False, "error": f"crawl4ai not installed: {e}", "url": url}
    except Exception as e:
        return {"success": False, "error": str(e), "url": url}


async def crawl_multi(urls: list[str], full: bool = False, timeout: int = 30) -> list[dict]:
    """Crawl multiple URLs with a controlled delay between them."""
    results = []
    for i, url in enumerate(urls):
        url = url.strip()
        if not url or url.startswith("#"):
            continue
        if not url.startswith(("http://", "https://")):
            url = "https://" + url
        result = await crawl_single(url, full, timeout)
        results.append(result)
        if i < len(urls) - 1:
            await asyncio.sleep(2)  # Polite delay
    return results


def format_for_llm(results: list[dict] | dict) -> str:
    """Format crawl results as clean text for LLM consumption."""
    if isinstance(results, dict):
        results = [results]

    output = []
    for r in results:
        if r.get("success"):
            output.append(f"# Source: {r['url']}")
            if r.get("title"):
                output.append(f"## {r['title']}")
            output.append("")
            output.append(r.get("content", ""))
            output.append("\n---\n")
        else:
            output.append(f"# FAILED: {r['url']}")
            output.append(f"Error: {r.get('error', 'unknown')}")
            output.append("\n---\n")

    return "\n".join(output)


def is_allowed_url(url: str) -> bool:
    """Basic URL validation — blocks common non-HTTP schemes."""
    parsed = urlparse(url)
    if parsed.scheme not in ("http", "https"):
        return False
    # Block local/internal addresses
    hostname = parsed.hostname or ""
    if hostname in ("localhost", "127.0.0.1", "0.0.0.0") or hostname.endswith(".local"):
        return False
    # Block common non-crawlable patterns
    blocked_patterns = [
        r"\.(pdf|zip|tar\.gz|exe|dmg|iso)$",
        r"mailto:",
        r"tel:",
    ]
    for p in blocked_patterns:
        if re.search(p, url, re.IGNORECASE):
            return False
    return True


def main():
    parser = argparse.ArgumentParser(description="NEO-Scraper — Web page extractor")
    parser.add_argument("urls", nargs="*", help="URL(s) to crawl")
    parser.add_argument("--input", "-i", help="File with URLs (one per line)")
    parser.add_argument("--output", "-o", help="Output file path")
    parser.add_argument("--format", choices=["text", "json"], default="text",
                        help="Output format (default: text)")
    parser.add_argument("--full", action="store_true", help="Extract full content (no truncation)")
    parser.add_argument("--timeout", type=int, default=30, help="Timeout per URL in seconds")

    args = parser.parse_args()

    # Collect URLs
    urls = list(args.urls)
    if args.input:
        with open(args.input) as f:
            urls.extend(line.strip() for line in f if line.strip())

    if not urls:
        print("Error: No URLs provided. Pass URLs as arguments or use --input.")
        sys.exit(1)

    # Validate URLs
    valid = []
    for url in urls:
        if not url.startswith(("http://", "https://")):
            url = "https://" + url
        if not is_allowed_url(url):
            print(f"Skipping disallowed URL: {url}", file=sys.stderr)
            continue
        valid.append(url)

    if not valid:
        print("Error: No valid URLs to crawl.", file=sys.stderr)
        sys.exit(1)

    # Crawl
    if len(valid) == 1:
        results = asyncio.run(crawl_single(valid[0], args.full, args.timeout))
    else:
        results = asyncio.run(crawl_multi(valid, args.full, args.timeout))

    # Output
    if args.format == "json":
        output = json.dumps(results, indent=2)
    else:
        output = format_for_llm(results)

    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"Output written to {args.output}")
    else:
        print(output)


if __name__ == "__main__":
    main()
