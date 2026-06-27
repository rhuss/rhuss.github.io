---
title: "What Goes in AGENTS.md (and What Doesn't)"
date: 2026-06-26
slug: "what-goes-in-agents-md"
description: "Three papers studied what works in AGENTS.md files. Here's what belongs inside, what to leave out, and how it coexists with CLAUDE.md."
tags: ["agents-md", "context-engineering", "ai", "claude-code"]
keywords: ["AGENTS.md", "CLAUDE.md", "context engineering", "AI coding agents", "context files", "AAIF", "agent configuration"]
images: ["/images/what-goes-in-agents-md/og.jpg"]
draft: false
license: "CC BY 4.0"
---

Every coding agent has its own context file. CLAUDE.md for Claude Code, `.cursorrules` for Cursor, `.github/copilot-instructions.md` for Copilot, GEMINI.md for Gemini CLI. If you work with more than one agent, you end up maintaining multiple files with [90% identical content](https://www.morphllm.com/agents-md-guide). AGENTS.md is the attempt to end that.
<!--more-->

{{< figure src="/images/what-goes-in-agents-md/hero.jpg" alt="Watercolor illustration of a wooden bulletin board nailed to a fence post in a sheep meadow. A large clean sheet pinned to the center is labeled AGENTS.md with bullet points. Smaller curling notes overlap around it, labeled CLAUDE.md, .cursorrules, GEMINI.md, and copilot-instructions.md. A sheep with round reading glasses studies the main sheet. Other sheep graze in the background with crumpled notes stuck in their wool." >}}

## Why AGENTS.md

The problem AGENTS.md solves isn't technical, it's organizational. Build commands, test instructions, code style rules, project architecture notes are the same regardless of which agent reads them. Copying them into four different files and keeping them in sync is maintenance that adds no value.

[AGENTS.md](https://agents.md/) is plain markdown with no required fields, no YAML frontmatter, and no special syntax. Write headings and bullet points, and the agent reads them and adjusts its behavior. It already works with [30+ agents](https://agents.md/) and sits under the [Agentic AI Foundation](https://aaif.io/projects/agents-md/) alongside MCP and Goose. Like README.md and CONTRIBUTING.md, agents discover it automatically by looking for the file in the directory tree.

That's the format, and the format is right. Plain markdown as the lowest common denominator is exactly what a universal standard needs to be. The question is what goes inside, and three academic papers published in 2026 have started to answer it.

## What the research says

The [ETH Zurich evaluation](https://arxiv.org/abs/2602.11988) tested four coding agents (Claude Code, Codex, Qwen Code) across 138 real-world tasks. The findings challenged the assumption that more context is always better:

- **LLM-generated context files hurt performance.** Success rates dropped by 0.5-2%, and inference costs went up by 20-23%. In five out of eight tested configurations, having an auto-generated file was worse than having no file at all.
- **Human-written files help modestly.** Success improved by about 4% across all agents.
- **Codebase overviews are useless.** Every LLM-generated file included one. They didn't help agents find relevant files faster. In many cases agents took more steps with overviews present.
- **The redundancy proof:** When the researchers removed *all* documentation from the repos, LLM-generated context files suddenly helped (+2.7%). The files were duplicating information the agents already extracted from README files and docs on their own.

A [separate study](https://arxiv.org/abs/2601.20404) showed the flip side: *curated, minimal* AGENTS.md files with only three content categories (coding conventions, architecture, project description) reduced median wall-clock time by 28% and output tokens by 16%. Less content, better results.

The [MSR '26 survey](https://arxiv.org/abs/2510.21413) of 10,000 repositories paints a broader picture: only 5% had adopted any context file format, the mean AGENTS.md file was 142 lines long, and half of all AGENTS.md files had zero commits after creation. Most are still write-once-and-forget.

The practical takeaway from [Augment Code's guide](https://www.augmentcode.com/guides/how-to-build-agents-md) captures the consensus: write only what agents can't discover on their own.

## What goes in, what doesn't

Based on the research and my experience maintaining context files across 38 projects, here's a quick reference:

**Put in AGENTS.md** (agents can't discover this on their own):

| Content | Example |
|---------|---------|
| Non-obvious build commands | `uv pip install -e ".[dev]"` not just `pip install` |
| Tool-specific choices | "Use `podman` not `docker`", "Use `rg` not `grep`" |
| Testing strategy | "Run `make e2e` for integration tests, requires Kind cluster" |
| Counterintuitive conventions | "Commit messages use DCO sign-off: `git commit -s`" |
| Hard invariants | "The UID in the Dockerfile must match `runAsUser` in Go" |
| Security boundaries | "Never commit `.env` or `.mcp.json` files" |
| PR/review expectations | "All PRs require at least one approval from CODEOWNERS" |

**Leave out of AGENTS.md** (agents figure this out already):

| Content | Why it's noise |
|---------|---------------|
| Codebase overviews | Empirically useless per ETH study, agents read the directory tree |
| Standard framework conventions | React, Express, Rails conventions are in the model's training data |
| README content | Agents read README.md on their own |
| Dependency lists | `package.json`, `Cargo.toml`, `requirements.txt` exist for this |
| File-by-file descriptions | Agents explore the codebase as needed |

**Keep it short.** Aim for under 150 lines. The efficiency study's best results came from files with just three sections, and every instruction beyond the essentials burns tokens and can actively degrade performance.

## Claude Code and AGENTS.md

One thing to know: Claude Code does not read AGENTS.md natively, only CLAUDE.md. To have Claude Code pick up your AGENTS.md content, reference it from your CLAUDE.md using the import syntax:

```markdown
@AGENTS.md
```

This loads the AGENTS.md content into Claude Code's context alongside whatever Claude-specific instructions you have in CLAUDE.md. The two files coexist in the same repo, but they serve different purposes.

**AGENTS.md** holds everything that's universal across agents: build commands, test instructions, conventions, architecture notes, security boundaries. Any agent that reads the file benefits from this content.

**CLAUDE.md** holds what only Claude Code understands: skills tables and routing rules, context loading directives (`@ARCHITECTURE.md`), subagent delegation patterns, context budget management, hook-based context injection, and plugin paths using `${CLAUDE_PLUGIN_ROOT}`. Other agents would ignore or misinterpret these instructions.

In practice, this means your CLAUDE.md becomes much shorter. It starts with `@AGENTS.md` to import the universal content, then adds only the Claude-specific configuration below it. Across my 38 projects, roughly 55% of the instructions in my CLAUDE.md files are universal and could move into AGENTS.md. The remaining 45% is either Claude-specific (30%) or uses Claude-specific language for what could otherwise be universal advice (15%).

The same pattern applies to other tools. Cursor users would keep their `.cursorrules` for Cursor-specific features (like glob-based conditional rule activation) and point to AGENTS.md for the shared content. Copilot users do the same with `.github/copilot-instructions.md`.

This isn't a migration from CLAUDE.md to AGENTS.md. It's a separation of concerns: AGENTS.md as a README for all agents, CLAUDE.md as a configuration file for one specific agent.

## The hard part

AGENTS.md standardizes the right thing at the right time. The format works, the ecosystem is growing, and the convergence problem it addresses was real and getting worse.

But the research is clear about one thing: auto-generating these files with an LLM makes things worse, not better. The files that actually change agent behavior are hand-crafted, containing the counterintuitive choices, the hard-won invariants, and the security boundaries that someone learned the hard way. Twenty-six percent of my own context files were auto-generated by a tool, and they're all thin and formulaic compared to the hand-written ones.

The spec gives you a place to put instructions. Deciding what belongs there is [context engineering](/context-engineering-101/), and that's a practice you build through experience, not a file you generate once and forget.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
