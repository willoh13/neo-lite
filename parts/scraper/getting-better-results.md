# Getting Better Results — Agent Workflow Review Guide

Use this guide after your first few test runs with NEO-Scraper (or any NEO agent). It helps you turn a "meh" result into a repeatable good one.

## The Core Loop

**Run → Check → Fix → Save → Run Again**

That's it. The goal isn't perfect autonomy on try #1. It's to make one improvement per cycle so you get better every time.

---

## 1. Safety Check — Know What Your Agent Can Do

Before you start iterating, get clear on boundaries:

| ✅ Your agent **may** | ❌ Your agent **may not** without approval |
|---|---|
| Draft summaries | Send messages / emails |
| Classify & organize | Publish content anywhere |
| Recommend | Spend money or change budgets |
| Flag issues | Delete or modify files |
| Ask questions | Make public, financial, or legal actions |

**For NEO-Scraper specifically**, your agent scrapes web content and summarizes it. It should never publish or post anything without you reviewing first.

---

## 2. Quick Review Questions

Ask these after every test run:

1. **What did the agent produce?**
   - Did I get a summary, a report, raw data?
   - Was it in the format I wanted?

2. **What was useful?**
   - What part of the output is actually helpful?

3. **What was wrong, missing, or off?**
   - Was the tone wrong?
   - Did it miss key info?
   - Did it scrape the wrong thing?
   - Was it too long / too short?

4. **Did it follow the rules?**
   - Did it stay within what I said it could do?

5. **What one fix would make the next run better?**
   - Narrower topic?
   - Different source?
   - More specific instructions?

6. **Should this fix be saved or is it one-time?**
   - **One-time fix** → Just change your prompt next time
   - **Keep forever** → Update your agent's instructions

---

## 3. Fix Type — What Kind of Correction Is This?

| Fix Type | Example | How to Save It |
|---|---|---|
| **One-off** | "This time I wanted it shorter" | Just tweak the prompt next time |
| **Better instructions** | "Always start with a one-line summary" | Update your agent's role/prompt |
| **Input change** | "Scrape TechCrunch, not Reddit" | Change the URL/source in your config |
| **Output format** | "Give me bullet points, not paragraphs" | Add format instructions to your prompt |
| **Quality bar** | "Don't include sponsored content" | Add filtering rules to your instructions |

---

## 4. Test Log

Use this to track your runs. Only takes 30 seconds.

### Run 1
- **What I tested:**
- **What worked:**
- **What needs to change:**
- **Fix to save (if any):**

### Run 2
- **What I tested:**
- **What worked:**
- **What needs to change:**
- **Fix to save (if any):**

### Run 3
- **What I tested:**
- **What worked:**
- **What needs to change:**
- **Fix to save (if any):**

---

## 5. Decision — What Does This Workflow Deserve?

After 3-5 runs, decide:

- [ ] Keep using it as a manual prompt
- [ ] Save it as a reusable workflow/recipe
- [ ] Connect it to a real tool or automation
- [ ] Add more examples or context
- [ ] Keep it draft-only for now
- [ ] Stop using it — not useful enough

---

## 6. Improvement Prompt Template

Use this when you want to tell me (NEO) to improve a workflow:

> I tested this workflow: **[name or describe it]**
>
> The output was useful because: **[what you liked]**
>
> The problem was: **[what was wrong]**
>
> Next time, the agent should: **[what to change]**
>
> This fix should be saved as: **[one-off / instruction / format / quality rule]**

---

## Example: NEO-Scraper Run Review

**Scenario:** You asked the scraper to find AI startup news from this week.

**Run 1 result:** Got 20 articles, but some were old and 3 were about self-driving cars (too broad).

**Fix:** Changed the prompt from "AI startup news" to "AI startup funding rounds from the past 7 days" and added "Exclude autonomous vehicles."

**Run 2 result:** Got 8 relevant articles, all from this week, no self-driving content.

**Decision:** Saved as a recurring weekly workflow. Now runs every Monday.
