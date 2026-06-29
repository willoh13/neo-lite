#!/usr/bin/env python3
"""
Create Ollama model variants with reasoning mode disabled via system prompt.

Background: gemma4 and qwen3 models use Ollama's reasoning mode by default,
which puts output in a 'reasoning' field instead of 'content'. This breaks
the OpenAI-compat layer that Hermes uses. The fix is to create variants
with a system prompt that suppresses reasoning.

Usage:
    python3 create_direct_variants.py [model1 model2 ...]

If no models specified, creates all three default variants:
    gemma4-e4b-direct, gemma4-26b-direct, qwen3-27b-direct
"""
import urllib.request
import json
import sys

SYSTEM_PROMPT = (
    "ABSOLUTE INSTRUCTION: Output ONLY the final answer in the 'content' field. "
    "NEVER use a 'reasoning' or 'thinking' field. NEVER include chain-of-thought. "
    "Just give the direct answer immediately. If you need to think, think "
    "internally but only return the final answer."
)

DEFAULT_VARIANTS = [
    ("gemma4:e4b", "gemma4-e4b-direct"),
    ("gemma4:26b", "gemma4-26b-direct"),
    ("qwen3.6:27b", "qwen3-27b-direct"),
]

def create_variant(base: str, variant: str, ollama_url: str = "http://localhost:11434") -> bool:
    """Create a -direct variant. Returns True on success."""
    # First try to delete any existing variant
    del_req = urllib.request.Request(
        f"{ollama_url}/api/delete",
        data=json.dumps({"name": variant}).encode(),
        headers={"Content-Type": "application/json"},
        method="DELETE",
    )
    try:
        urllib.request.urlopen(del_req, timeout=10).read()
    except urllib.error.HTTPError as e:
        if e.code != 404:  # 404 = didn't exist, that's fine
            print(f"  WARN: delete returned {e.code}")
    except Exception:
        pass  # ignore other errors on delete

    # Create the new variant
    create_req = urllib.request.Request(
        f"{ollama_url}/api/create",
        data=json.dumps({
            "model": variant,
            "from": base,
            "system": SYSTEM_PROMPT,
        }).encode(),
        headers={"Content-Type": "application/json"},
    )

    print(f"Creating {variant} from {base}...")
    try:
        with urllib.request.urlopen(create_req, timeout=180) as resp:
            body = resp.read().decode()
            # Ollama streams NDJSON; last line has the final status
            lines = [l for l in body.splitlines() if l.strip()]
            if lines:
                last = json.loads(lines[-1])
                if last.get("status") == "success":
                    print(f"  ✓ {variant} created")
                    return True
                else:
                    print(f"  ✗ {last}")
                    return False
    except Exception as e:
        print(f"  ✗ Error: {e}")
        return False

def main():
    # If user passed models on CLI, parse them as "base->variant" pairs
    if len(sys.argv) > 1:
        variants = []
        for arg in sys.argv[1:]:
            if "->" in arg:
                base, variant = arg.split("->", 1)
                variants.append((base, variant))
            else:
                print(f"Skipping malformed arg: {arg} (expected base->variant)")
    else:
        variants = DEFAULT_VARIANTS

    success_count = 0
    for base, variant in variants:
        if create_variant(base, variant):
            success_count += 1

    print(f"\n{success_count}/{len(variants)} variants created.")
    print("Test with: curl http://localhost:11434/v1/chat/completions -d '{\"model\": \"gemma4-e4b-direct\", ...}'")
    sys.exit(0 if success_count == len(variants) else 1)

if __name__ == "__main__":
    main()
