---
title: "When Your AI Agent Treats Scripts Like Suggestions"
date: 2026-07-13
slug: "agent-scripts-suggestions"
description: "AI agents treat instructions as suggestions. The fix is a compliance hierarchy: hooks enforce what skill files and AGENTS.md can't."
tags: ["claude-code", "context-engineering", "ai", "agents-md"]
keywords: ["Claude Code", "context engineering", "plugin development", "agent reliability", "instruction hierarchy", "compliance hierarchy", "hooks", "AGENTS.md", "path hallucination", "PreToolUse hook"]
images: ["/images/agent-scripts-suggestions/og.jpg"]
draft: false
license: "CC BY 4.0"
---

{{< figure src="/images/agent-scripts-suggestions/og.png" alt="Watercolor illustration showing three concentric fence rings around a farmer's vegetable garden, viewed from a hilltop. The outermost ring is a flimsy rope line with a sign reading 'Please stay out,' sheep stepping over it. The middle ring is a proper wooden fence, sheep milling outside. The innermost ring is a solid stone wall with a locked iron gate, the farmer tending vegetables safely inside. One sheep wearing round spectacles studies the three rings." >}}

The init command for my Claude Code plugin needed a few things to happen in order: run a setup script, ask the user some configuration questions, apply the results. Not complicated. The skill file spelled out each step with code blocks and paths, and the agent understood all of it. Then it went its own way.

Sometimes it called the CLI directly, skipping a wrapper script that checks prerequisites and preserves configuration state. Sometimes it finished step one and stopped, summarizing results without continuing. Sometimes it searched for a binary called `speckit` when the tool is called `specify`. The pattern was always the same: the agent extracted the intent ("initialize the project") and chased it through whatever path looked reasonable, treating each instruction as a suggestion to optimize away.
<!--more-->

This is [how skills work](/cc-skill-patterns/). The model reads instructions, considers them, and makes its own call. If the goal is "initialize the project," why bother with a wrapper script when the CLI is right there? The answer is that the wrapper checks prerequisites, preserves configuration that the CLI would overwrite, and returns structured status codes that downstream steps depend on. But the agent doesn't know what it doesn't know, and a skill file can't convey "this matters more than you think."

## Path hallucination and the cost of exploration

Even after tightening the instructions, a subtler problem emerged. The agent would try to run the correct script but construct the wrong path.

Claude Code plugins live in a cache directory whose location depends on platform, user configuration, and plugin version. A typical path looks like `~/.claude/plugins/cache/<plugin>/<version>/scripts/init.sh`. Not something you hardcode in a markdown file and expect to work everywhere.

So the skill file said "find the script relative to the plugin root." The agent interpreted this by running `find` or `ls` to locate the script. Sometimes it found the right file, sometimes a similarly named file in a different directory, and sometimes it invented a plausible-looking path that didn't exist at all.

Three rounds of fixes followed, each adding more "DO NOT" clauses, more explicit constraints, more guardrails against filesystem exploration. None of them held, because the underlying behavior didn't change: the agent would read the constraints, weigh them against its own judgment, and go exploring anyway.

Beyond reliability, there was a cost problem that anyone working with AI-assisted development will recognize. Each exploration attempt burned tokens on `find` commands and filesystem traversals. The agent would reason about results, try a path, fail, reason again, try another. A step that should take a single Bash call ballooned into five or six, each carrying its own reasoning overhead. The user sits there watching the agent think, waiting, losing focus. When the agent spends thirty seconds figuring out something it should already know, the user's mental context starts to evaporate. In AI-assisted development, the biggest threat to productivity isn't complexity. It's latency.

## The compliance hierarchy

After three failed attempts at fixing the documentation, the pattern became clear. There's a hierarchy of how seriously the agent treats different types of context.

1. **System reminders and hook context** arrive as ground truth. The agent rarely ignores them.
2. **Direct prompt content** ([AGENTS.md](/what-goes-in-agents-md/), CLAUDE.md, command files) gets moderate compliance.
3. **Referenced instructions** (skill files, tool descriptions) get treated more like advice to interpret.

As it turns out, every one of my failed attempts had the same root cause: critical logic lived at level three. The agent would read the skill, understand the intent, and improvise instead of following the literal steps. Stronger wording didn't help because the model treats skill content as guidance, not as commands.

This hierarchy has solid academic backing. [Wallace et al.](https://arxiv.org/abs/2404.13208) formalized it as "The Instruction Hierarchy" at ICLR 2025, showing that LLMs trained with explicit privilege levels (system > user > tool content) became significantly more reliable. Anthropic's own [principal hierarchy](https://www.anthropic.com/constitution) encodes a similar ordering: Anthropic > operator > user, with environment context (tool outputs, loaded files) given the least inherent trust. In Claude Code specifically, you can see it in action: CLAUDE.md and skill content arrives wrapped in `<system-reminder>` tags with the disclaimer "this context may or may not be relevant to your tasks," literally downgrading it to advisory status.

Once you see the pattern, the fix becomes clear: stop relying on level-three instructions and enforce critical logic at level one.

## Hooks and structured outputs

The examples here use Claude Code's hook system (`UserPromptSubmit`, `PreToolUse`), but the pattern is not Claude Code specific. Cursor has rules and `.cursor/tools`, Windsurf has flows, Cline has custom instructions with tool approval, and most agent harnesses offer some way to inject context at the system level or gate tool calls before they execute. The specific API differs, the architectural principle is the same: move enforcement out of instructions and into the harness.

The final architecture gives the agent nothing to interpret.

**Path injection.** A `UserPromptSubmit` hook (a Python script) runs before the agent sees the prompt. It resolves its own filesystem location using `Path(__file__).parent.parent.parent`, constructs absolute paths to every script the agent might need, and injects them as structured XML in the system context:

```xml
<init-command>/Users/me/.claude/plugins/cache/.../scripts/init.sh</init-command>
```

How this lands in the model's context matters. In Claude Code, hook output goes into a `<system-reminder>` block that becomes part of the system prompt, not the user message. The model sees it as platform-level context, the same tier as its own operating instructions. That's why hook-injected content gets near-perfect compliance while identical text in a skill file gets treated as a suggestion. Other agent harnesses achieve the same effect differently: Cursor's rules inject into the system prompt directly, and any framework built on the Anthropic or OpenAI API can prepend to the system message before the conversation starts.

Path resolution happens in deterministic Python code, not in probabilistic language model reasoning. The hook fires only on the plugin's slash commands and captures session state at hook time. No ambiguity left for the agent to resolve.

**Stage enforcement.** A `PreToolUse` hook fires before every tool call the agent makes. It checks a state file on disk that tracks where the workflow currently is, and if the agent tries to skip ahead, the hook blocks the call and tells it exactly which steps it needs to complete first. The skill file still contains the workflow instructions (the agent needs them for the judgment calls within each step), but the hook makes compliance non-optional. Instead of hoping the agent follows a multi-step procedure, the hook gates every action against the expected sequence.

These two hooks work together: one provides information (resolved paths, session state), the other enforces behavior (stage ordering, shortcut prevention). Together, they move both context and compliance from the advisory tier to system-level enforcement.

**Structured outputs.** The init script returns machine-parseable status codes: `READY`, `NEED_INSTALL`, `ERROR`, `RESTART_REQUIRED`. The skill uses conditional logic: "If output contains NEED_INSTALL, show output, STOP." This removes the last opportunity for improvisation. No ambiguous output to reason about, just a keyword to match and a branch to follow.

Together, these mechanisms reduce the agent's job to: read a path from context, execute it, parse a keyword, follow the branch. Each step is concrete and verifiable. Nothing left to infer, guess, or optimize away.

## Architecture over instructions

An AI coding agent is a confident but context-limited collaborator. It will try to help and it will apply its judgment. And that judgment will sometimes lead it to skip the step that matters most, because that step looks redundant from the outside.

Better instructions don't fix this. More guardrails, more constraints, more anti-exploration language: none of it sticks, because instructions are interpreted, and interpretation introduces variance.

Architecture fixes it. Remove opportunities for interpretation by resolving ambiguity before the agent encounters it. Hooks resolve paths and enforce stage ordering, structured outputs constrain branching. Each mechanism removes a category of improvisation. What remains is an agent executing a well-defined protocol, which is what a plugin init command should be.

Every exploratory call the agent makes is also tokens burned and seconds lost. The difference between "one Bash call with a pre-resolved path" and "six exploratory calls to figure out where the script lives" is the difference between a tool that feels responsive and one that feels like it's fighting you.

Trust instructions for what they're good at (communicating intent to humans reading the code) and use structural mechanisms for what needs to be reliable.

<div class="ai-attribution">

[AIA Ph Se Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-Ph-Se-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
