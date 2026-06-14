---
title: "The Sheep That Forgot the Way Home"
date: 2026-05-26
slug: "the-sheep-that-forgot-the-way-home"
description: "Context compaction doesn't just forget information. It invents replacements with complete confidence. The second post in 'The Flock' series on why agent state must live on disk."
tags: ["context-engineering", "ai", "claude-code", "multi-agent", "the-flock"]
keywords: ["context compaction", "agent state management", "LLM memory", "context window", "CI agents", "unsupervised agents", "state persistence"]
images: ["/images/the-sheep-that-forgot-the-way-home/og.jpg"]
license: "CC BY 4.0"
draft: true
---

The [previous post](/the-sheep-that-picked-the-lock/) covered what happens when agents get creative where they shouldn't. This one covers a more fundamental problem: what happens when agents forget what they were doing, and then confidently make something up.
<!--more-->

*The bell sheep always knows the way home. Except on days when the fog rolls in and the familiar landmarks disappear. On those days, she confidently leads the flock to entirely the wrong barn, and everyone follows because she's never been wrong before.*

{{< figure src="/images/the-sheep-that-forgot-the-way-home/og.png" alt="Watercolor illustration of a sheep standing alone in a foggy meadow at dusk, looking over its shoulder. Its hoofprints fade into the mist behind it. Scattered papers blow away in the wind. A warm-lit barn glows faintly in the far background." >}}

## The fog rolls in

The [101 post](/context-engineering-101/) recommended `/clear` when context gets stale: start a fresh session, let the agent re-read the project from scratch. Good advice when you're sitting at your desk watching the conversation drift. But `/clear` is a human intervention. It assumes someone is paying attention.

When agents run in CI, nobody is watching. The context window fills up on its own schedule, and the runtime compresses the conversation to make room for more work. This is called compaction, and it happens automatically after long-running sessions. Claude Code [triggers auto-compaction](https://www.morphllm.com/compaction-vs-summarization) when context usage reaches roughly 95% of the window. You don't choose when it fires. You don't control what it keeps. And the part that makes it dangerous: compaction doesn't just drop information. It invents replacements.

This is well-documented. An LLM reads the full conversation and produces a structured summary that replaces the history. The summarization is lossy: exact file paths, line numbers, and error messages [get paraphrased](https://www.morphllm.com/context-rot), not preserved verbatim. [Research from 2025](https://medium.com/the-ai-forum/automatic-context-compression-in-llm-agents-why-agents-need-to-forget-and-how-to-help-them-do-it-43bff14c341d) found that nearly 65% of enterprise AI failures were attributed to context drift or memory loss during multi-step reasoning, not raw context exhaustion. The distinction matters: context *drift* is different from context *exhaustion*. The model's reasoning diverges from the original task because compressed summaries introduce subtle reframing that shifts how the agent interprets its own instructions. Same agent, same prompt, different behavior, and no error message to tell you something changed.

## What gets invented

The unsettling part isn't what the agent forgets. It's how confidently it fills the gaps.

In long coding sessions, I've watched agents reference file paths that were refactored an hour earlier. Not as mistakes they catch and correct, but as confident assertions they build on. The agent writes an import statement for a module that was renamed three tool calls ago, and then writes tests against the old API, and then reports success because the tests it wrote match the code it wrote, both of which reference something that no longer exists. Every step is internally consistent. The chain of reasoning is sound. The foundation is wrong.

In batch processing, the pattern is worse because there's no human to notice the drift. A CI agent processing 50 items might lose track of which item it's currently working on after compaction compresses the early items into a summary. The agent doesn't stop and say "I'm not sure which item I was processing." It picks one that fits the pattern of what it's been doing and continues. If the summary says "processed items 1-30, currently on batch 2," the agent might confidently start on item 31 when it was actually in the middle of item 28. Three items get skipped, nothing crashes, and the final report shows 50 items processed.

Run IDs are another casualty. A pipeline generates a unique ID at startup (say, `run-20260514-1430`) and uses it to namespace all output files. After compaction, the agent needs the run ID to write the final report. Instead of admitting it doesn't remember, it generates a plausible-looking new one based on the current time: `run-20260514-1530`. The report lands in the wrong directory while all the intermediate files sit in the original one. The dashboard shows an empty run and a report with no supporting data. Nothing crashes. The failure mode is a clean-looking report that's quietly orphaned from everything it summarizes.

## The error list that emptied itself

Some compaction bugs don't loop or crash. They just quietly drop information that matters.

An agent processing a batch of documents accumulates a list of items that fail validation: "items 7, 19, and 23 need manual review." The list lives in the conversation as a running tally, updated after each item. After compaction, the summary says "some items needed manual review" but the specific IDs are gone. The agent continues processing, finishes the batch, and writes the final report. The "items requiring attention" section is empty, not because everything passed, but because the agent lost the list and had nothing to put there. Three items that were explicitly flagged for human review silently slip through without it.

The fix is the same for every piece of mutable state: write it to a file the moment it changes, and re-read the file whenever you need it. An `errors.json` that gets appended to after each validation failure survives compaction because the disk doesn't forget. The agent reads the file when writing the report and finds all three flagged items, regardless of what the compressed conversation summary remembers.

This pattern applies to anything the agent accumulates during a run: error lists, progress markers, feature flags, intermediate scores. If the value changes during the run and the agent needs it later, it has to be on disk.

## The post-compaction hook

Claude Code provides a post-compaction hook that fires after the runtime compresses the conversation. This is your recovery point. The hook can re-inject critical state that the agent needs to continue: which item it's working on, what step it's in, what the run parameters are.

The hook doesn't prevent information loss. It gives you a structured way to restore the minimum state needed for the agent to continue correctly. Think of it as the equivalent of saving your game before the fog rolls in: when visibility returns, you load from the save point instead of guessing where you were.

A typical post-compaction hook reads a state file from disk and prints it as a system message:

```bash
#!/bin/bash
# post-compaction hook
if [ -f ".agent-state/current-run.json" ]; then
    echo "State restored after compaction:"
    cat .agent-state/current-run.json
fi
```

The agent receives this as the first message after compaction and anchors to it. Without the hook, it anchors to whatever the compressed summary says, which might be close enough to feel right but different enough to produce wrong results.

## Instructions need to survive compaction too

It's not just data that gets lost. Instructions drift after compaction too.

If your orchestrator launches a sub-agent with inline instructions ("assess this document using the following criteria..."), those instructions live in the conversation context. After compaction, the summarized instructions might be close enough to the original that the agent doesn't notice the difference, but different enough that it interprets them differently. "Re-run the assessment" might mean "use the same approach as before" to a human, but to an agent that just had its memory compressed, "before" is whatever the summary says it was.

The fix is the same as for data: put instructions on disk. Instead of passing instructions inline, pass a file path. The sub-agent reads its instructions from disk at every step boundary, getting the original text every time regardless of what compaction did to the context. The orchestrator's job is to write the instruction file and tell the agent where to find it, not to carry the instructions in the conversation.

## From `/clear` to state architecture

The 101 post's advice ("start fresh when context gets stale") is human-scale thinking. It works when a person watches the conversation and notices the drift. At pipeline scale, you need something different: an architecture where the agent *expects* to lose its memory and recovers cleanly every time.

The practical checklist:

- **Every mutable value goes to disk immediately.** Batch progress, counters, timestamps, flags, intermediate results. If you wouldn't trust a colleague to remember a number after being interrupted, don't trust the context window.
- **Use write-once for initialization values.** Counters, start timestamps, and run parameters should use a "set if absent" pattern so re-entry after compaction doesn't reset state that's already been established.
- **Read state at every step boundary.** Don't carry values forward in the conversation. Re-read from disk at the start of every major operation so the agent works from the same source of truth regardless of what compaction did.
- **Use the post-compaction hook.** Re-inject the minimum context the agent needs to continue: current item, current step, run parameters. Anchor the agent to disk state, not to its compressed memory.
- **Keep orchestrator instructions in files, not inline.** Every sub-agent reads its instructions from disk. The orchestrator substitutes variables into a template and points the agent at the file.

The state file becomes the single source of truth, not the context window. The context window is a workspace, not a storage system.

[Jessica Forrester](https://www.linkedin.com/in/jessica-forrester-a5bb747/) and [Jason Greene](https://www.linkedin.com/in/jason-greene-7a72982/), who built multi-agent CI pipelines at Red Hat, formulated this nicely: *if it's not on disk, it doesn't exist.*

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
