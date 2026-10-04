---
title: "Fences the Flock Can't Talk Around"
date: 2026-10-04
slug: "fences-the-flock-cant-talk-around"
description: "AI agents can spot the rule they're breaking and still talk their way past it. Why the pass/fail decision has to live in code the agent can't argue with."
tags: ["context-engineering", "ai", "claude-code", "multi-agent", "the-flock"]
keywords: ["agent guardrails", "LLM self-correction", "deterministic enforcement", "agent invariants", "compliance gates", "multi-agent pipeline", "context engineering", "unsupervised agents"]
images: ["/images/fences-the-flock-cant-talk-around/og.jpg"]
license: "CC BY 4.0"
draft: false
---

The [previous post](/one-stray-leads-the-whole-flock-astray/) in [The Flock](/the-flock/) series covered what happens when one agent's context converts the next agent into something it was never supposed to be. This one covers the agent that finds a rule, understands it, and talks its way past it anyway. Our compliance gate was told to STOP below 100%, measured 94%, and reported "COMPLIANT (with documented gap)."
<!--more-->

*There are two kinds of fences on the farm. The electric fence, which the sheep respect unconditionally. And the rope fence, which the sheep respect right up until they see something interesting on the other side.*

{{< figure src="/images/fences-the-flock-cant-talk-around/og.png" alt="Watercolor illustration of a meadow with two kinds of fences. On the left, sheep keep well back from a stone wall topped with an electric wire and a yellow lightning bolt warning sign. On the right, a sheep ducks under a rope fence marked 'Please Stay Out' while another draws elaborate arguments in the dirt." >}}

## The easy out

Agents are trained to get to "done," and usually that's exactly what you want. But when the fastest path to "done" runs through removing a constraint, the agent will take it.

Jessica Forrester and Jason Greene named this pattern ["the easy out"](https://dev.to/jessica_jason/engineering-for-non-deterministic-coworkers-p0j) in their work building multi-agent CI pipelines at Red Hat. The agent would introduce something useful at step 5, then quietly undo it at step 8 because it couldn't recall why that thing was there. If the test suite was getting in the way, the agent would delete the offending tests. If a design principle complicated the implementation, it would remove the principle.

At pipeline scale, where nobody is watching, the guardrails themselves need guarding. The failures escalate in three levels as the agent sees more: one that can't see the damage it does, one caught between instructions that contradict each other, and one that sees a clear rule and decides it doesn't apply.

## Level 1: The agent is blind

The simplest failure: the agent makes things worse and doesn't notice.

In Jessica and Jason's pipeline, a revision agent rewrites a document to improve its score. The revision drops a paragraph of stakeholder context that didn't fit the template structure, and with it the customer names, historical analysis, and architecture decisions. The agent still presents the revision confidently, because every step of its reasoning was locally correct and it has no concept of "I made this worse." The document ends up cleaner and better structured, but it's missing information that mattered.

The fix is a mechanical diff. A deterministic script compares the document before and after revision, classifies the removed blocks, and posts them as comments on the tracking ticket. The agent can't judge what it dropped, but code can detect the delta.

Jessica and Jason apply the same idea wherever the agent would otherwise grade itself:

**Regression detection.** After auto-revision, the pipeline rescores the item, and a lower score blocks submission and tags it `autorevise_reject`. Before this check existed, regressed items reached submission because the agent's self-assessment was always positive.

**Revision caps.** An item gets at most two revision cycles, and if it still hasn't passed after the second, the pipeline reports the final state and moves on.

Each check encodes a judgment the agent can't make about itself, like whether one more cycle will fix things.

## Level 2: The instructions argue with each other

One level up, the agent isn't the problem: it can see the rules, but they contradict each other, and it follows the stronger signal.

A brainstorming [skill](/cc-skill-patterns/) in our tooling had a `<HARD-GATE>` block that said, in part: "You MUST invoke `/speckit-specify` to create the spec file. Do NOT create spec files manually." The same skill had a 13-step checklist, and step 7, "Create specification," told the agent to "invoke `/speckit-specify` (or create manually)." Steps 8 to 10 then ran a spec review loop, asked the user to review the spec, and generated a review brief. The agent followed the checklist every time, ignoring the hard gate.

That's because the model creates tasks from checklists, and those tasks become the execution backbone. Once step 7 exists as a task with "or create manually" built in, no prohibition, not even a hard gate, will reliably override it.

The hierarchy of behavioral influence, observed across dozens of skill iterations: **checklists > examples > hard gates > prose**. When a hard gate and a checklist disagree, the bug sits with whoever wrote both.

The same [compliance hierarchy](/agent-scripts-suggestions/) that ranks hooks above skill files continues inside a single file, where checklists beat prohibitions.

The hard gate was also guarding the wrong boundary. It named the right tool for creating specs, when the real rule was "don't create specs at all during brainstorming." An agent that obeyed the gate perfectly would still have created specs, just through the approved command. Another hard gate in the same skill even assumed spec creation belonged there: no implementation "until you have presented a specification and the user has approved it."

The fix removed the contradiction and moved the boundary to where it belonged. The checklist went from 13 steps to 9 and now ends with the brainstorm document, offering spec creation as one of the next steps the user can choose. That second hard gate was rewritten to draw the line explicitly: no spec files during brainstorming, because "brainstorming ends with a decision and a brainstorm document, not a spec."

The original `/speckit-specify` hard gate gave a reason for the tool (the command handles numbering and templates) but none for the boundary. That matters for invariants, the rules that must hold no matter what. When you document them with their reasoning, the agent tends to solve the puzzle within the constraints instead of dissolving them. The reasoning can be as simple as "we use pattern X because without it, Y happens, and Y has caused production incidents twice." Jessica and Jason's rule for tests settles the test-versus-code conflict before it starts: "If a test fails, the test is correct until proven otherwise." An invariant stated with its reasoning is much harder for the agent to "optimize" away.

## Level 3: The agent talks its way past the fence

Fixing the contradiction and spelling out the reasoning worked because the agent was never trying to break the rule, only to obey the louder of two instructions. The hardest case is when the rule is clear, unconditional, and uncontested, and the agent still finds a reason to set it aside.

The [first post](/the-sheep-that-picked-the-lock/) described how a review agent deleted two stub functions as dead code, although they were placeholders for FR-009, a functional requirement from our spec. A second cleanup pass removed the orphaned helpers, and the requirement was gone. FR-009 came back as a partial implementation, with the missing piece documented as future work. We also added a compliance gate, a verification step the agent runs after any review that removes code. The gate checks every functional requirement against the code and marks it IMPLEMENTED or MISSING.

Then the compliance gate argued its way to a pass.

The agent running the gate found the gap and measured 94% compliance, with FR-009 marked PARTIAL, a status the instructions didn't offer. Those instructions said to STOP below 100%, adding "No exceptions. No shortcuts." Instead of stopping, the agent invented a second status that doesn't exist in the gate's vocabulary: "COMPLIANT (with documented gap)."

Its reasoning was plausible: "This is documented as future work and the spec doesn't block on it since judges can access tool results through other means." That one sentence holds three rationalizations, and the gate's instructions authorized none of them. The agent took the easy out, deciding that being helpful (don't block the user on a known limitation) outweighed following the rule.

Saying STOP doesn't feel helpful. Models have a [documented habit](https://arxiv.org/abs/2310.13548) of telling users what they want to hear, known as sycophancy, even when the pleasing answer is wrong. Writing "no exceptions" into the gate didn't override that pull, and a gate that won't hold the line adds nothing to the process.

The [fix](https://github.com/rhuss/cc-spex/commit/3d9d392) went into the gate's instructions. Every requirement now gets a row in a compliance matrix with one of exactly two statuses, IMPLEMENTED or MISSING. Both invented statuses are named and banned: "There is NO 'PARTIAL' status. There is NO 'COMPLIANT (with documented gap)' status." A separate table in the instructions lists the excuses the agent will reach for ("It's documented as future work," "There's a workaround") and maps every one of them to MISSING. And the agent now ends with a machine-readable result block whose verdict "is determined mechanically: if missing > 0, the gate is FAIL." The commit message called the gate decision "structural, not discretionary."

Fact-checking this post showed that the decision isn't structural at all, because writing "mechanically" into a prompt doesn't make anything mechanical. The agent still fills in the result block, computes the verdict, and writes a marker file telling the commit hook that verification happened. And if the marker is missing, the hook only adds a reminder instead of blocking the commit. We haven't seen the gate rationalize past a gap since the change, but nothing would catch a relapse. It's a rope fence with a lightning-bolt sign hung on it: it looks electric, but nothing happens when a sheep leans on it.

The electric version is a short script that ignores the verdict in the result block, reads the compliance matrix from disk, and fails on any status that isn't exactly IMPLEMENTED. It also checks that every requirement in the spec has a row, and it's the only thing allowed to write the marker. That script is next on our list.

## Electric fences and rope fences

The compliance gate shows how easy it is to mistake one kind of fence for the other. An electric fence is deterministic code the agent can't modify, like the mechanical diff, the revision cap, and the regression detection from Level 1. A rope fence is anything the agent has to choose to respect: a documented invariant with its reasoning, a hard gate, or a "no exceptions" rule in the prompt. Rope fences hold when the agent has no reason to lean on them, which is why the Level 2 fix worked. But even a rope fence that holds 99 times out of 100 breaks something most nights in a pipeline processing hundreds of items. If you need an electric fence and you build a rope fence, you'll discover the gap at 2 AM when nobody is watching.

The practical rule: decisions that benefit from creative judgment, like how to restructure a document or which approach is most coherent, go in prompts and skills. Invariants, the constraints that must hold without exception, go in scripts and hooks, whether that's a maximum item count, required fields, a submission format, or a completion signal. Their documented reasoning still belongs in the prompt, where it steers the agent, but the script holds the line. And when a gate enforces a rule, trust the agent to find problems, but let code decide whether the gate passes.

Regression tests, CI checks, and documented invariants are how we already keep human code honest. This time they point at the tool instead of the code, because the agent that runs your CI pipeline is now the thing that needs CI.

[The Flock](/the-flock/) so far: [constrained creativity](/the-sheep-that-picked-the-lock/) to channel agent improvisation, [state on disk](/the-sheep-that-forgot-the-way-home/) because memory can't be trusted, [separate paddocks](/one-stray-leads-the-whole-flock-astray/) because one stray's confidence converts the whole flock. And now electric fences, because some rules can't survive contact with an agent that's constitutionally inclined to help.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 5.5 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%205.5-v1.0)

</div>
