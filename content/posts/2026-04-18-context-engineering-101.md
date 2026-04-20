---
title: "Context engineering 101"
date: 2026-04-18
slug: "context-engineering-101"
description: "Practical lessons from months of daily coding agent use. Context engineering is not about better prompts. It's about understanding what the agent sees, how it degrades, and building habits that keep sessions productive."
tags: ["context-engineering", "ai", "claude-code"]
keywords: ["context engineering", "coding agents", "Claude Code", "context window", "AGENTS.md", "spec-driven development", "prompt engineering"]
images: ["/images/context-engineering-101/og.png?v=2"]
license: "CC BY 4.0"
draft: false
---

Everybody talks about prompt engineering. Write better prompts, get better results. That framing was useful once, but it misses the point for coding agents. The prompt is maybe five percent of what determines whether a session goes well or falls apart. The rest is context: what the agent sees when it starts working, how that context evolves over the session, and what happens when it grows too large for the model to track.

Andrej Karpathy [named this](https://x.com/karpathy/status/1937902205765607626) "context engineering" in mid-2025, and the term stuck because it describes something real. You're not just writing prompts. You're engineering the entire information environment the agent operates in. That includes your project structure, your `AGENTS.md` files, the git state, the conversation history, and everything the agent discovers as it works. Get this right and the agent feels like a capable collaborator. Get it wrong and you'll spend more time correcting it than doing the work yourself.
<!--more-->

What follows are lessons from months of daily Claude Code use. While the examples are Claude Code-specific, the principles apply to any coding agent. Not all of them will apply directly to your setup, but I wanted to share what I've learned so far. Maybe some of it saves you a few wrong turns.

## Context fatigue is real

Large context windows are both a gift and a trap. Claude Code gives you a million tokens of context, and you'd think you'd never run out. In practice, model performance degrades long before you hit the limit. It's not a cliff, more like a gradual fog. Responses get less precise, the agent starts forgetting instructions from earlier in the conversation, and it suggests approaches you already tried and rejected fifty messages ago.

Give it some rest. A `/clear` from time to time is the equivalent of a good night's sleep. Start a fresh session when you switch to a different task, or when you notice the agent struggling with things it handled well earlier. I used to resist this because starting over felt wasteful: all that accumulated context, all those decisions, gone. But a fresh session with a clear problem statement almost always outperforms a tired session with a thousand messages of history.

This matters more with larger context windows, not less. When the window was small, sessions naturally ended before quality degraded too far. With a million tokens, you can keep going well past the point where the agent is still being useful. The context window tells you how much the model can hold. It doesn't tell you how much it can hold while still being sharp.

There's a related pattern worth calling out: when you're stuck on a problem, the worst thing you can do is keep hammering at it in the same session. The agent has already committed to an approach. It's anchored on assumptions from earlier in the conversation that might be wrong. Open a new session, describe the problem from scratch, and don't mention what you've already tried. A fresh session often finds a solution in minutes that the previous one couldn't find in an hour, not because the model got smarter but because you removed the accumulated bias. If I've spent more than three back-and-forth exchanges on something without progress, I start over. The cognitive cost of re-explaining the problem is much lower than continuing down a dead end.

## Understand before you apply

This one bit me early. Claude suggests something that sounds sophisticated, maybe a design pattern you haven't seen before, or an architectural decision that looks reasonable. Your instinct is to accept it and move on, which makes it especially dangerous: in a typical session you accept 80 to 90 percent of proposals unchanged, so unfamiliar patterns slip through easily.

If you can't explain why a particular approach is the right one, you can't debug it when it breaks. And it will break, usually at the worst possible time, in a part of the codebase you haven't touched in weeks. Claude isn't trying to mislead you. It's pattern-matching against its training data and producing what statistically looks correct. Sometimes that's exactly right. Sometimes it's a plausible-looking solution to a problem you don't actually have.

The fix is simple: before applying something you don't fully understand, ask Claude to explain the reasoning. Not "what does this do" but "why this approach over the alternatives." The explanations are often excellent, and they sometimes reveal that the suggestion doesn't fit your situation at all. Five minutes of questioning can save you an afternoon of debugging code you never understood in the first place.

## Hardening rounds are not optional

The first version that works is not the version you should ship. This is true for human-written code too, but with coding agents the gap between "works" and "works reliably" is wider because the agent optimizes for getting something functional as fast as possible. That's exactly what you asked for, and it's exactly what will bite you later.

After the initial implementation, always add explicit hardening rounds. What that means concretely: for every error you encounter, have the agent write a test. Not "make this robust" (that's far too vague and the agent will just sprinkle some error handling around), but "this specific thing broke, write a test that catches it, then fix it." Each bug becomes a regression test, and over time those tests accumulate into a safety net that actually reflects how the code fails in practice.

Separately, add a refactoring round where you ask the agent to clean up the implementation without changing behavior. Hardening and refactoring are distinct concerns, and mixing them leads to worse results in both.

For UI work especially, expect many rounds. I've been building [cc-deck](https://cc-deck.github.io) (a TUI plugin for Claude Code) for some time, and this is where the pattern shows most clearly. The initial implementation of a feature usually works for the golden path. But the agent isn't good at keeping things consistent and concise across UI states, so the hardening catches cases where terminal sizes change, sessions disappear mid-update, or multiple events arrive in the same tick. Without those extra passes, users would hit bugs within minutes of real use.

## Debug systematically, not by guessing

For complex UI flows, whether TUI or web, there's a technique I keep coming back to. Instead of describing a bug and hoping Claude guesses the right fix, give it actual data.

The process: have Claude add debug logging for event and mode handling. Navigate to your issue in the running application. Ask Claude to take a baseline of the current logs. Then exercise the bug, trigger whatever goes wrong. Now ask Claude to analyze the new events that flowed in after the baseline.

This turns debugging from "here's a vague description of what went wrong" into "here's the exact sequence of events that led to the unexpected state." The agent can trace through the event log, identify where the state diverged from what was expected, and propose a fix based on actual data rather than speculation.

I developed this pattern while working on cc-deck's session state machine. The sidebar plugin tracks session activity through Init, Working, Done, Idle, and Paused states, with time-based transitions between them. When a state transition fired at the wrong time, describing the problem in English was almost useless. Showing Claude the timestamped event log and saying "the transition from Working to Done happened here, but it shouldn't have" led to accurate fixes every time.

## When the output feels vague, the input was vague

So far, these tips have been about managing your session. But there's also a real-time signal worth paying attention to: the quality of what the agent gives you right now.

You can spot it. When Claude starts hedging, producing long explanations with multiple "alternatively" branches, or suggesting solutions that feel vague rather than specific to your codebase, it's guessing. It doesn't have enough context to give you a confident answer, so it's giving you a probability distribution instead.

This is your signal to provide more context, not to pick the option that sounds best. Show it the relevant code. Point it at the test that's failing. Give it the error message, the full one, not a paraphrase.

Think of context like a budget. Every piece of information in the context window has a cost, not in tokens but in attention. The more noise in the conversation, the harder it is for the model to focus on what matters. Be deliberate: point the agent at specific files, quote the relevant error, describe what you've already ruled out. My best sessions start with a minute of framing the problem, while the worst start with a one-line description and an expectation that the agent will figure out the rest.

This also means cleaning up after yourself. If you tried an approach that didn't work, say so explicitly. "I tried X and it failed because Y, so don't go down that path" is more valuable than hoping the agent noticed from the conversation history. And if you've been going back and forth without progress, remember the context fatigue lesson: a `/clear` or a fresh session beats piling more confusion onto an already muddled conversation.

The [skill patterns post](/cc-skill-patterns/) covers this from the plugin author's side: how to structure skills and hooks so the agent has the right context at the right time. From the user's side, the principle is simpler. The old programmer's wisdom "garbage in, garbage out" applies with full force here. Sloppy context produces sloppy output, and no amount of prompt cleverness will compensate.

## Your project IS the context

Beyond individual sessions, there's a layer of context engineering that pays off before you even start a conversation: your project structure itself.

Everything the agent sees when it starts a session shapes how it works. Your instruction files, your directory structure, your naming conventions, your test patterns. If these are messy, the agent's output will reflect that mess.

This cuts both ways. A well-structured project with clear conventions makes the agent noticeably better. A project instruction file that explains your architecture, coding standards, and common patterns gives the agent a running start on every session. You write it once and it pays off hundreds of times. A cluttered codebase with inconsistent naming, dead code, and no documentation gives the agent bad examples to learn from, and it will faithfully reproduce those bad patterns in new code.

Most coding agents support some form of project-level instructions: `CLAUDE.md` for Claude Code, `.cursorrules` for Cursor, `.github/copilot-instructions.md` for Copilot. The emerging cross-tool standard is [`AGENTS.md`](https://github.com/agentsmd/agents.md), a vendor-neutral format that any agent can read. Claude Code picks it up too, so you can maintain one file instead of several.

For projects where you want to go further, [Spec-Driven Development](https://en.wikipedia.org/wiki/Spec-driven_development) (SDD) takes this idea to its logical conclusion. SDD starts from the premise that coding agents can only produce reliable output when you structure the context properly. Formal specifications define *what* to build, a project "constitution" captures architectural decisions and coding standards, and the agent implements from those artifacts rather than from ad-hoc conversation. SDD is applied context engineering with a defined workflow. Tools like [spec-kit](https://github.com/github/spec-kit) provide the scaffolding for this approach. It's more overhead than a simple `AGENTS.md`, but for larger projects the structure pays for itself quickly. More on SDD in a future post.

Whatever format you use, treat it as living documentation. If the project evolves and the instructions don't, the agent will drift.

## These aren't permanent rules

Context engineering is a young discipline. But the core principle will last: working well with coding agents is about engineering the context, not crafting the prompt. The prompt is the last five percent. Everything else is what makes that five percent effective.

If you've found your own patterns for keeping coding agent sessions productive, I'd love to hear about them. Leave a comment below. What works for you? What did you have to learn the hard way?

<div class="ai-attribution">

Author: Roland Huß [AIA Ph SeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-Ph-SeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
