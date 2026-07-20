---
title: "One Stray Leads the Whole Flock Astray"
date: 2026-07-20
slug: "one-stray-leads-the-whole-flock-astray"
description: "In multi-agent pipelines, context contamination doesn't confuse the next agent. It converts it. Isolation is the fix, not better prompts."
tags: ["context-engineering", "ai", "claude-code", "multi-agent", "the-flock"]
keywords: ["context contamination", "multi-agent isolation", "adversarial review", "anchoring bias LLM", "agent context bleed", "cross-context review"]
images: ["/images/one-stray-leads-the-whole-flock-astray/og.jpg"]
draft: false
license: "CC BY 4.0"
---

The [previous post in The Flock series](/the-sheep-that-forgot-the-way-home/) covered what happens when agents forget mid-run and confidently fill the gaps. This one covers a different failure mode: what happens when one agent's leftover context converts the next agent into something it was never supposed to be.
<!--more-->

*The flock grazes in separate paddocks for a reason. Put the bell sheep and the border collie in the same field and by afternoon the collie has stopped herding and started grazing. It didn't forget its job. It absorbed the bell sheep's confidence and decided that grazing was the job all along.*

{{< figure src="/images/one-stray-leads-the-whole-flock-astray/og.png" alt="Watercolor illustration of a forking dirt path in a green meadow. On the left fork, three sheep walk confidently toward a rickety old barn. On the right fork, the main flock heads toward a warm stone barn with a glowing doorway. A low stone wall with a gap separates the two paths. Wildflowers line the wrong path on the left." >}}

## Not confusion, conversion

Context contamination between agents is a different beast than context fatigue within a single session. The [101 post](/context-engineering-101/) covered the gradual fog: responses getting less precise as the conversation grows, state drifting after compaction. That's a single agent slowly losing its footing.

In multi-agent setups, the failure is sharper. When multiple agents run in the same foreground context, the second agent doesn't just inherit stale data from the first. It inherits the first agent's *identity*. An assessment agent that follows a creation agent in the same context will absorb the creator's assumptions and biases. In the worst cases it adopts the creator's role entirely, deciding that its job is to generate ideas rather than evaluate them, not confused but converted.

## Context bleeds across items, not just across roles

The second pattern is subtler. A feasibility agent reviewing multiple items in sequence can have context from one item bleeding into the assessment of the next. Scores that should be independent aren't. The fix is the same: one agent per item, each in complete isolation.

This kind of bleed only surfaces at scale. Small test batches of five items look fine. At fifty, the drift becomes visible: items assessed later in the sequence show score patterns that correlate with properties of earlier items, not their own content.

[Lou and Sun (2026)](https://link.springer.com/article/10.1007/s42001-025-00435-2) found that anchoring bias in LLMs is systematic and affects stronger models more consistently, not less. Four different debiasing strategies (chain-of-thought, reflection, ignoring anchor hints, explicit instructions) all failed to eliminate it. Prompt engineering can't fix a bias baked into how the model processes sequences. Architecture can.

## The author can't review its own work

Code review culture already solved this problem for humans. You don't review your own pull requests because you're anchored to the decisions that shaped the code. You see the logic, not the gaps. As it turns out, the same principle applies to agents.

The [CCR paper](https://arxiv.org/abs/2603.12123) (Cross-Context Review) tested this directly. Fresh-session review achieved an F1 score of 28.6% versus 24.6% for same-session self-review. The critical control was reviewing twice in the same session: that produced more findings but *worse* precision (21.0% vs 25.8%), more noise rather than more signal. The production context itself anchors the model, and repeating review in the same context only makes things worse.

CCR also achieves what the authors call "natural anonymization." The reviewing session can't know the artifact originated from the same model. This mirrors findings from [Choi et al. (ACL 2026)](https://arxiv.org/abs/2510.07517) showing that sycophantic bias drops 96% when authorship is hidden. The model is more honest when it doesn't know it's reviewing its own work.

This is why adversarial review works as a pipeline pattern. An agent creates or revises a document in one context. A completely separate agent, running in a clean context, assesses the result. The reviewer doesn't know that a revision happened, doesn't have access to the creation reasoning, and evaluates the output on its merits alone.

## The workbench metaphor

Think of context like a workbench in a shared workshop. If the previous worker left their tools, materials, and half-finished pieces scattered around, the next worker will unconsciously start incorporating those into whatever they're building. Clearing the bench between workers isn't overhead, it's a prerequisite for getting independent results.

Multi-agent frameworks take different positions on when to clear the bench. Claude Code subagents enforce isolation by default: each subagent runs in a fresh conversation with its own system prompt and tool definitions, but not the parent's conversation history. The OpenAI Agents SDK takes the opposite approach, sharing full conversation history by default during handoffs, though it provides an `input_filter` mechanism for opt-in isolation. These are different architectural philosophies, and the research consistently favors isolation.

## From discipline to architecture

Context contamination can't be solved with better prompts. Anchoring bias resists all tested prompt-based mitigations, sycophancy persists as long as authorship is visible, and score drift accumulates as long as items share a context.

The fix is structural: separate creation from assessment, isolate items from each other, clear the context between agents, and make the reviewing agent blind to the creation process. These aren't optimizations you add after the pipeline works. They're prerequisites for the pipeline producing reliable results.

The [first post in this series](/the-sheep-that-picked-the-lock/) called for deterministic guardrails around agent creativity. The [second](/the-sheep-that-forgot-the-way-home/) called for state on disk because memory can't be trusted. This one adds: separate the paddocks, because one stray's confidence is enough to convert the whole flock.

<div class="ai-attribution">

[AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
