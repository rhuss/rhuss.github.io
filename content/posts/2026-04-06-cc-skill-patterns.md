---
title: "Claude Code skill patterns"
date: 2026-04-06
slug: "cc-skill-patterns"
description: "Practical patterns from building Claude Code skills. The separation between skills and scripts, why Claude keeps taking shortcuts, and how hooks enforce what instructions can't."
tags: ["claude-code", "context-engineering", "ai"]
license: "CC BY 4.0"
draft: true
---

The most important thing I learned building Claude Code skills is this: know when you need an LLM, and when you need a script.

That sounds obvious, but it isn't. When you build skills for a coding agent, the temptation is to let the agent handle everything because it's smart, flexible, and can figure things out on the fly. But "figuring things out" is exactly the problem when you need the same thing to happen the same way every time.
<!--more-->

The examples here come from [cc-prose](https://github.com/rhuss/cc-prose) (voice-consistent writing) and [cc-spex](https://github.com/rhuss/cc-spex) (spec-driven development on top of [spec-kit](https://github.com/github/spec-kit)), among others. Each skill taught me something about what works and what breaks when you're programming the context rather than the code.

## Skills are suggestions

This is the most important insight for skill authors: Claude treats skill content as advice, not as instructions.

A skill that says "always use spec-kit to create the specification" might get followed, or Claude might decide it already has enough context from the brainstorming phase to write the spec directly, skipping the tool entirely. It's being helpful, but it's also wrong.

Stronger wording does not help. I tried "MUST", "ALWAYS", "CRITICAL", bold, uppercase. None of it changes the fundamental dynamic: the model reads your skill, considers it, and then makes its own judgment call. Compare that to hook-injected context (system reminders), which Claude treats as ground truth. This difference in compliance is not a bug, it's how the architecture works. Understanding it early saves you from writing increasingly aggressive skill instructions that still get ignored.

## The shortcut race

This shortcutting behavior deserves its own section because it keeps coming back.

You fix one shortcut in your skill instructions, Claude finds another path around it, you patch that one, and it discovers a third. It's a classic [Hase-und-Igel](https://en.wikipedia.org/wiki/The_Hare_and_the_Hedgehog) race, and as the skill author you will always be the hedgehog.

In cc-spex, the brainstorming phase collects requirements, explores alternatives, and validates assumptions before the specification phase formalizes everything into a proper spec using spec-kit. But Claude regularly decides that the brainstorming output is "structured enough" and writes the spec directly. From the model's perspective, this is a reasonable optimization. From the workflow's perspective, it's skipping the entire point.

What makes this particularly frustrating is that Claude usually knows it did the wrong thing. Point out the shortcut and it will apologize, acknowledge that it should have followed the workflow, and promise to do better next time. A kind of too-late self-reflection that doesn't actually prevent the next occurrence.

A useful debugging technique is to open a fresh session, show Claude what happened, and ask it *why* it took the shortcut. The answers are surprisingly informative. "The brainstorming output contained enough structured information that creating a spec felt like a natural next step" is the kind of reasoning you get. You take that insight and fix the skill in yet another clean session. It's a loop, but each iteration makes the skill more reliable.

The question is now: can you win this race? Not entirely. But you can make shortcuts increasingly expensive for the model by moving critical logic out of skills and into scripts and hooks, where it stops being a suggestion and becomes a constraint.

<div class="diagram-themed">
<img class="diagram-light" src="/images/cc-skill-patterns/enforcement-architecture-light.svg" alt="Enforcement architecture: hooks inject state and block shortcuts, skills provide advisory guidance, scripts handle deterministic state management" />
<img class="diagram-dark" src="/images/cc-skill-patterns/enforcement-architecture-dark.svg" alt="Enforcement architecture: hooks inject state and block shortcuts, skills provide advisory guidance, scripts handle deterministic state management" />
</div>

## Skills vs scripts

This leads directly to the core design decision: what belongs in a skill, and what belongs in a script?

**Skills** give you flexibility, error-forgiveness, and adaptability. The LLM can handle ambiguous input, recover from unexpected situations, and apply judgment, so use them when the outcome benefits from interpretation.

**Scripts** give you determinism, repeatability, and predictability because a Python script does the same thing every time. Use them when the outcome must be consistent across runs.

Let me illustrate with two examples.

One of my plugins has a workflow for processing external PDF reviews. You iterate over reviewer comments, map them to source files, assess complexity, and generate fix proposals. This follows a fixed procedure with multiple stages. Early versions used skills for the whole flow, and the result was a different experience every time: sometimes it would skip comments, sometimes it would process them in the wrong order, sometimes it would invent stages that didn't exist. A `session_manager.py` script now handles the state management, tracks the interaction state, and stores results. The skill handles the judgment calls within each stage, like assessing whether a reviewer's suggestion actually improves clarity. The script handles everything else.

Another plugin needed multi-level authentication: Kerberos ticket, then cloud provider connection, then cluster connection, then the target environment. Doing this with just a skill was maddening because every run produced a different login sequence. Some runs it would try the cloud connection before the Kerberos ticket, some runs it would skip steps it considered "already done." A login script made it deterministic.

The evolution path is predictable: you start with a simple prompt-only skill (just English instructions, fragile by nature) and gradually move state management into scripts as you hit consistency problems. And of course, you don't write those scripts by hand. You tell Claude "let's create a script to make this more predictable" and let it build the script and wire it into the skill at the right checkpoints. The rule of thumb I've settled on is that every state change should go through a script. Let the LLM do the thinking, and let scripts do the bookkeeping.

## Hooks over hopes

If skills are advisory and scripts are deterministic, hooks are the bridge. Claude Code's hook system lets you inject context at specific points in the interaction, and that context arrives as a system reminder. Claude treats system reminders as ground truth, not as suggestions to consider.

I arrived at this pattern after several failed attempts at writing better skill instructions. More context, clearer wording, stricter language, none of it helped reliably. Claude would follow the instructions most of the time, then helpfully deviate at the worst possible moment. The hook-based approach works because it stops being about persuasion and starts being about enforcement.

cc-spex uses a `PreToolUse` hook as a guardrail layer. When the plugin runs a multi-stage ship workflow (brainstorm, specify, plan, implement, review, verify), Claude regularly tries to skip stages. A skill instruction saying "complete each stage in order" gets interpreted as a suggestion. The hook makes it a constraint: if Claude tries to jump from stage 2 (spec review) to stage 6 (implementation), the hook blocks the tool call and lists every stage it needs to complete first:

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

The same hook also catches hallucinated commands (Claude inventing `/spex:specify` which doesn't exist) and reminds about verification before git commits. A companion `UserPromptSubmit` hook injects plugin state as a structured system reminder on every prompt, including the plugin root path, project configuration, and session context, so that skills always have accurate state without needing to rediscover it.

This is the key insight: instead of telling Claude what to do and hoping it complies, you build guardrails that make non-compliance impossible. The hooks don't ask Claude to follow the process, they enforce it at the tool level before Claude's output reaches the user.

## Finding your scripts

Once you've decided to move logic into scripts, a surprisingly tricky problem appears: how does a skill actually find and run a script that lives inside the plugin directory?

Claude Code provides a `${CLAUDE_PLUGIN_ROOT}` environment variable that gets substituted in hook configurations, so your `hooks.json` can reference `${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.py` and it will work. But this variable has been unreliable in other contexts. In earlier versions of Claude Code, it simply didn't work in command markdown files at all ([anthropics/claude-code#9354](https://github.com/anthropics/claude-code/issues/9354)), and the behavior has changed across releases.

The pattern that works reliably today is to let the hook script self-locate the plugin root from its own file path (in Python, something like `Path(__file__).parent.parent.parent`) and then inject the resolved path as part of the system reminder context:

```xml
<plugin-context>
<plugin-root>/Users/me/.claude/plugins/cache/my-plugin/1.0.0</plugin-root>
<init-command>/Users/me/.claude/plugins/cache/my-plugin/1.0.0/scripts/init.sh</init-command>
</plugin-context>
```

This way, skills get fully resolved paths that are ready to use, with no template substitution needed and no dependency on environment variables being available. The hook does the path resolution once, and every skill in the plugin benefits from it.

This is another area where things are actively improving, and at some point a simple `${CLAUDE_PLUGIN_ROOT}` reference might be all you need. But for now, the hook-based path injection is the most reliable approach I've found.

## Building on a moving platform

Claude Code is moving from `commands/` to user-invocable `skills/`, and the documentation already treats `skills/` as the standard while commands are on the way out.

But the transition isn't smooth yet. Plugin skills installed from marketplaces don't appear in the `/` slash command autocomplete ([anthropics/claude-code#18949](https://github.com/anthropics/claude-code/issues/18949), open since January 2026 with multiple duplicate issues and no fix yet). cc-spex had to revert from `skills/` back to `commands/` to maintain usability, because users who can't discover your skills simply won't use them.

This is what building on a fast-moving platform looks like: the gap between documented direction and actual tool behavior is real, and it shifts with every release. My approach is to build with `skills/` as the primary structure but keep thin `commands/*.md` stubs as a bridge until autocomplete catches up. The stubs will be dead code soon enough.

## Patterns in brief

A few more patterns that came up across my skills.

**User-invocable skills.** Skills are becoming executable and replacing the old `commands/` directory, with each skill living in `skills/<name>/SKILL.md` where it can be invoked directly as a slash command. Keep the skill frontmatter lean and put the workflow logic in the body, which can grow to 500 or even 1500 lines per skill.

**Multi-specialist over monolith.** Instead of one massive skill that tries to do everything, split into independent specialist skills with their own activation rules. One of my plugins uses 12 specialists for different editing concerns: style, consistency, flow, references, links, examples, and more. This keeps individual skills focused and within context budget, because one monolithic skill will lose track of its own instructions.

**Prevention over correction.** The prose plugin generates clean content upfront using voice profiles and AI pattern avoidance, rather than generating text and then running a fixer pass. It's cheaper to prevent bad output than to detect and fix it after the fact. Not to mention that fixing AI-generated text while using AI tends to be an exercise in whack-a-mole.

**Keep skills small.** Every line of skill content fills the context window, so if Claude "helpfully" adds optional features to your skill output, remove them. Periodic cleanup during development is important because skill code accumulates cruft faster than regular code.

**Configuration hierarchy.** Skill defaults in `knowledge-base/` get overridden by global user config, which gets overridden by project config. cc-prose uses this to layer project-specific voice profiles on top of general writing defaults. Three layers is enough. More than that and you're debugging configuration inheritance instead of writing skills.

## Where this is going

Skill development for coding agents is still new territory, and the patterns described here will evolve as the platform matures, context windows grow, and models get better at following instructions. Some of these workarounds will become unnecessary while new problems emerge.

But the core tension between flexibility and determinism, between skills and scripts, won't go away with better models. If anything, more capable models will just make the shortcut race more creative.

If you're building Claude Code skills and have found patterns of your own, I'd like to hear about them.

<div class="ai-attribution">

Author: Roland Huß [AIA Ph SeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-Ph-SeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
