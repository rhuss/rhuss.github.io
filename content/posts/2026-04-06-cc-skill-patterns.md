---
title: "Claude Code skill patterns"
date: 2026-04-06
slug: "cc-skill-patterns"
description: "Practical patterns from building Claude Code skills. Why skills are suggestions not instructions, how hooks enforce what skills can't, and when to reach for a script."
tags: ["claude-code", "context-engineering", "ai"]
license: "CC BY 4.0"
draft: true
---

Claude Code skills let you extend a coding agent with custom workflows, specialist knowledge, and automation. You write a `SKILL.md` file with instructions, and the agent follows them. At least, that's the idea.

In practice, Claude treats skill content as advice, not as instructions. A skill that says "always use spec-kit to create the specification" might get followed, or Claude might decide it already has enough context from the brainstorming phase to write the spec directly. It's being helpful, but it's also wrong. This post describes patterns for dealing with that challenge, from scripts that enforce consistency to hooks that block shortcuts before they happen.
<!--more-->

Stronger wording does not help. I tried "MUST", "ALWAYS", "CRITICAL", bold, uppercase. None of it changes the fundamental dynamic: the model reads your skill, considers it, and then makes its own judgment call. Compare that to hook-injected context (system reminders), which Claude treats as ground truth. This difference in compliance is not a bug, it's how the architecture works. Understanding it early saves you from writing increasingly aggressive skill instructions that still get ignored.

The patterns in this post come from building [cc-prose](https://github.com/rhuss/cc-prose) (voice-consistent writing), [cc-spex](https://github.com/rhuss/cc-spex) (spec-driven development on top of [spec-kit](https://github.com/github/spec-kit)), and a few others.

## The shortcut race

This shortcutting behavior keeps coming back and deserves its own section.

You fix one shortcut in your skill instructions, Claude finds another path around it, you patch that one, and it discovers a third. It's a classic [Hase-und-Igel](https://en.wikipedia.org/wiki/The_Hare_and_the_Hedgehog) race, and as the skill author you will always be the hedgehog.

In cc-spex, the brainstorming phase collects requirements, explores alternatives, and validates assumptions before the specification phase formalizes everything into a proper spec using spec-kit. But Claude regularly decides that the brainstorming output is "structured enough" and writes the spec directly. From the model's perspective, this is a reasonable optimization. From the workflow's perspective, it's skipping the entire point.

What makes this particularly frustrating is that Claude usually knows it did the wrong thing. Point out the shortcut and it will apologize, acknowledge that it should have followed the workflow, and promise to do better next time, without that actually preventing the next occurrence.

A useful debugging technique is to open a fresh session, show Claude what happened, and ask: "Why did you do this, and how can we prevent it in the future?" The answers are surprisingly insightful, and many of the patterns in this post came directly from those conversations. Then I let Claude fix the skill right there in the same session, while the reasoning is still fresh. Each iteration makes the skill more reliable.

Can you win this race? Not entirely. But you can make shortcuts increasingly expensive for the model by moving critical logic out of skills and into scripts and hooks, where it stops being a suggestion and becomes a constraint.

## Skills vs scripts

Skills can call out to scripts during execution. This is the escape hatch from the shortcut race: instead of relying on Claude to follow a multi-step procedure described in English, you delegate the deterministic parts to a script that the skill invokes at the right moment. The question then becomes: what belongs in the skill, and what belongs in the script?

**Skills** give you flexibility, error-forgiveness, and adaptability. The LLM can handle ambiguous input, recover from unexpected situations, and apply judgment, so use them when the outcome benefits from interpretation.

**Scripts** give you determinism, repeatability, and predictability because a Python script does the same thing every time. Use them when the outcome must be consistent across runs.

One of my plugins has a workflow for processing external PDF reviews: iterate over reviewer comments, map them to source files, assess complexity, and generate fix proposals. This follows a fixed procedure with multiple stages. Early versions used skills for the whole flow, and the result was a different experience every time: sometimes it would skip comments, sometimes it would process them in the wrong order, sometimes it would invent stages that didn't exist. A `session_manager.py` script now handles the state management, tracks the interaction state, and stores results. The skill handles the judgment calls within each stage, like assessing whether a reviewer's suggestion actually improves clarity. The script handles everything else.

The evolution path is predictable: you start with a simple prompt-only skill (just English instructions, fragile by nature) and gradually move state management into scripts as you hit consistency problems. And you don't write those scripts by hand, either. You tell Claude "let's create a script to make this more predictable" and let it build the script and wire it into the skill at the right checkpoints. The rule of thumb: every state change should go through a script. Let the LLM do the thinking, and let scripts do the bookkeeping.

## Hooks over hopes

If skills are advisory and scripts are deterministic, hooks are the bridge. Claude Code's hook system lets you inject context at specific points in the interaction, and that context arrives as a system reminder, which Claude treats as ground truth. Better skill instructions won't fix the compliance gap, but hooks can enforce what instructions can't.

cc-spex uses a `PreToolUse` hook as a guardrail layer. This hook fires before every tool call and can either allow it, deny it with an error message, or inject additional context. When the plugin runs a multi-stage ship workflow (brainstorm, specify, plan, implement, review, verify), Claude regularly tries to skip stages. A skill instruction saying "complete each stage in order" gets interpreted as a suggestion. The hook makes it a constraint: a state file on the filesystem tracks the current pipeline stage, and the hook checks it before every tool call. If Claude tries to jump from stage 2 (spec review) to stage 6 (implementation), the hook blocks the call and lists every stage it needs to complete first:

```text
PIPELINE DISCIPLINE: You are trying to invoke speckit-implement 
(stage 6: implement) but the pipeline is at stage 2: review-spec. 
You MUST complete these stages first, in order:
  2. review-spec (spex:review-spec)
  3. plan (speckit-plan)
  4. tasks (speckit-tasks)
  5. review-plan (spex:review-plan)
Do NOT skip stages. Do NOT shortcut.
```

The same hook catches hallucinated commands (Claude inventing `/spex:specify` which doesn't exist) and reminds about verification before git commits. A companion `UserPromptSubmit` hook injects plugin state as a structured system reminder on every prompt, including resolved script paths, project configuration, and session context, so that skills always have accurate state without needing to rediscover it.

Instead of telling Claude what to do and hoping it complies, you build guardrails that make non-compliance impossible. The hooks don't ask Claude to follow the process, they enforce it at the tool level before Claude's output reaches the user.

<div class="diagram-themed">
<img class="diagram-light" src="/images/cc-skill-patterns/enforcement-architecture-light.svg" alt="Enforcement architecture: hooks inject state and block shortcuts, skills provide advisory guidance, scripts handle deterministic state management" />
<img class="diagram-dark" src="/images/cc-skill-patterns/enforcement-architecture-dark.svg" alt="Enforcement architecture: hooks inject state and block shortcuts, skills provide advisory guidance, scripts handle deterministic state management" />
</div>

## More patterns

A few more patterns that came up across my skills.

**Multi-specialist over monolith.** Instead of one massive skill that tries to do everything, split into independent specialist skills with their own activation rules. One of my plugins uses 12 specialists for different editing concerns: style, consistency, flow, references, links, examples, and more. This keeps individual skills focused and within context budget, because one monolithic skill will lose track of its own instructions.

**Prevention over correction.** cc-prose generates clean content upfront using voice profiles and AI pattern avoidance, rather than generating text and then running a fixer pass. It's cheaper to prevent bad output than to detect and fix it after the fact. Not to mention that fixing AI-generated text while using AI tends to be an exercise in whack-a-mole.

**Keep skills small.** Every line of skill content fills the context window, so if Claude "helpfully" adds optional features to your skill output, remove them. Periodic cleanup during development is important because skill code accumulates cruft faster than regular code.

**Configuration hierarchy.** Skill defaults in `knowledge-base/` get overridden by global user config, which get overridden by project config. cc-prose uses this to layer project-specific voice profiles on top of general writing defaults. Three layers is enough.

**Building on a moving platform.** Claude Code is transitioning from `commands/` to user-invocable `skills/`, but plugin skills installed from marketplaces still don't appear in the `/` slash command autocomplete ([anthropics/claude-code#18949](https://github.com/anthropics/claude-code/issues/18949), open since January 2026). Build with `skills/` as the primary structure but keep thin `commands/*.md` stubs as a bridge until autocomplete catches up.

The core tension between flexibility and determinism, between skills and scripts, won't go away with better models. If anything, more capable models will just make the shortcut race more creative.

If you're building Claude Code skills and have found patterns of your own, I'd like to hear about them.

<div class="ai-attribution">

Author: Roland Huß [AIA Ph SeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-Ph-SeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
