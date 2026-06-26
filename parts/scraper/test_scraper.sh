#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# NEO-Scraper — Test script
# Runs the scraper against a public URL to verify it works.
# ──────────────────────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRAPER="${SCRIPT_DIR}/scraper.py"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  NEO-Scraper Test Suite"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for crawl4ai
python3 -c "import crawl4ai" 2>/dev/null || {
    echo "❌ crawl4ai not installed. Run: pip install -r requirements-scraper.txt"
    exit 1
}

echo "✓ crawl4ai installed"

# Test 1: Single URL crawl
echo ""
echo "📝 Test 1: Single URL crawl (httpbin.org)"
OUTPUT=$(python3 "$SCRAPER" "https://httpbin.org/html" --format json 2>&1)
SUCCESS=$(echo "$OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('success', False))")
if [ "$SUCCESS" = "True" ]; then
    echo "  ✓ Successfully crawled httpbin"
else
    ERROR=$(echo "$OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error','unknown'))" 2>/dev/null)
    echo "  ✗ Failed: $ERROR"
fi

# Test 2: URL validation
echo ""
echo "📝 Test 2: URL validation (should skip localhost)"
OUTPUT=$(python3 "$SCRAPER" "http://localhost:8080/" 2>&1 || true)
if echo "$OUTPUT" | grep -q "disallowed"; then
    echo "  ✓ Correctly blocked localhost URL"
else
    echo "  ✗ Did not block localhost"
fi

# Test 3: Batch crawl from file
echo ""
echo "📝 Test 3: Batch crawl"
echo "https://httpbin.org/html" > /tmp/test_urls.txt
OUTPUT=$(python3 "$SCRAPER" --input /tmp/test_urls.txt --format json 2>&1)
SUCCESS=$(echo "$OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0].get('success', False) if isinstance(d,list) else False)" 2>/dev/null || echo "False")
if [ "$SUCCESS" = "True" ]; then
    echo "  ✓ Batch crawl works"
else
    echo "  ✗ Batch crawl failed"
fi
rm -f /tmp/test_urls.txt

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Tests complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
