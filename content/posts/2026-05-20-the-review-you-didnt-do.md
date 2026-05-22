---
title: "AI Wrote It. Nobody Read It."
date: 2026-05-20
slug: "ai-wrote-it-nobody-read-it"
description: "AI made writing cheap. It didn't make reading cheap. How to spot when the review was missing, and why it matters more for internal docs than anywhere else."
tags: ["ai", "documentation", "opinion", "quality", "context-engineering"]
keywords: ["AI documentation", "AI slop", "work slop", "document review", "technical writing AI", "documentation quality", "AI trust"]
images: ["/images/the-review-you-didnt-do/og.jpg"]
license: "CC BY 4.0"
draft: false
---

You're reading through a lengthy architecture proposal shared on a team channel, and something feels off. Near the end, tucked between the conclusion and the appendix, you find a section titled "Corrections Applied After Cross-Referencing: The following adjustments were made based on automated analysis of the upstream repository." Clearly, AI wrote most of this. And the review before sharing was either absent or superficial. You scroll back to the top and start reading the whole thing differently. Not engaging with the proposal anymore, but checking whether you can trust it at all.
<!--more-->

{{< figure src="/images/the-review-you-didnt-do/og.png" alt="Watercolor illustration of a sheep at a lectern proudly presenting a long scroll covered in text. The scroll has a TODO sticky note and crossed-out sections still visible. Other sheep in the audience look skeptical, one wearing glasses and squinting. A rubber stamp reading REVIEWED sits unused in its packaging." >}}

## The distinction that matters

There's nothing wrong with using AI to draft documentation. I do it regularly, and this blog is transparent about [how AI contributes to each post](https://aiattribution.github.io) (see the attribution at the bottom). The problem isn't AI-drafted content. It's content that went out as the final product, with nobody reading it through a reader's eyes before hitting send.

The cost is highest in *internal technical documentation*, because the audience is captive. Your colleagues can't just scroll past. They have to read it, or at least try to, because decisions depend on it. An [arXiv paper from March 2026](https://arxiv.org/html/2603.27249v1) frames this as a tragedy of the commons: the person who generates 30 pages saved an hour, but the 10 people who have to read it lost a day each. For a company of 10,000 employees, that [hidden cost runs to roughly $9 million per year](https://hbr.org/2025/09/ai-generated-workslop-is-destroying-productivity) in lost productivity. And [42% of workers](https://hbr.org/2025/09/ai-generated-workslop-is-destroying-productivity) say they trust colleagues *less* after receiving low-quality AI-generated content from them. The damage isn't just to the document. It's to the person who sent it. And once a reader spots the first sign, they shift from learning mode to checking mode, which is slower, more exhausting, and means every claim in the document gets a mental asterisk.

## The scaffolding nobody removed

The most obvious signs are process artifacts that were never meant for human readers. Sections like "Corrections from Verification," "Notes for the author," or "Based on analysis of the following sources:" are scaffolding from the generation process. They're instructions to or from the AI, not content for the reader. Leaving them in is the document equivalent of shipping debug logging to production.

LLM meta-comments are a related sign. "Here is a summary of the key findings..." or "The following section covers..." as actual content rather than transitional prose. The AI is narrating its own output. A human author would just write the summary. And revision notes in the body ("Updated: Added section on error handling based on reviewer feedback") belong in version control, not in what the reader sees.

These are the easy catches. If you find one, you know nobody read the document front to back before sharing it. But the deeper signs are about what's *missing* from the document, not what's left in it.

## No reader in mind

A lengthy technical document that doesn't tell you who it's for was written for the prompt, not for a reader. Human authors can anticipate their reader's perspective, gauge what needs explaining and what doesn't, and adjust the depth accordingly. AI writes for the instruction it received.

There are now [two fundamentally different audiences](https://dacharycarey.com/2026/02/26/llms-vs-agents-as-docs-consumers/) for documentation, and they need different things.

A document written for **human readers** should be concise, opinionated, and structured around tasks. Cut the redundancy, lead with what matters, add "you can skip this if you already know X" escape hatches. The reader's attention is the scarce resource.

A document written for **machine consumers** (coding agents, RAG pipelines, model training data) can be more verbose, include more detail, and tolerate repetition, because machines don't get bored or lose focus. They need explicit metadata, consistent terminology, and structured headings rather than visual layout cues. But the stakes are different too: inconsistencies and wrong information don't just confuse today's agent. In your RAG pipeline, they poison tomorrow's retrieval results. In training data, they get baked into model weights and produce wrong answers for years. Poorly reviewed docs fed into machine consumers make every AI system that reads them worse.

The problem isn't which audience you chose. The problem is not choosing. And that starts in the prompt: if you don't tell the AI who the reader is, what they already know, and what decision they need to make, you get the 30-page default. Everything covered at medium depth, no priorities, no opinion, no awareness of what the reader already knows or needs to decide. State your audience in the first paragraph. One sentence changes how everything that follows gets written and read.

## The signs that need a closer look

Beyond scaffolding and missing audience, there are subtler signs.

**Everything gets equal depth.** Real authors go deep on what matters and skim what doesn't, because they know which parts readers care about. AI gives every section the same level of detail. A three-paragraph introduction to HTTP status codes in a document about a specific API's error handling is a sign that nobody prioritized.

**No opinions, or opinions without reasoning.** Sometimes there's no recommendation at all: "Option A has these trade-offs. Option B has these trade-offs." If your architecture document doesn't recommend an architecture, someone is going to have to schedule a meeting to figure out what the document was trying to say. But the subtler version is a document that *does* recommend option A, lists two alternatives that were "considered," and never explains why they were rejected. A real author who evaluated three approaches can tell you what was wrong with the other two, not just what was right with the chosen one. AI picks the option that fits the prompt best and moves on, leaving the reader to guess whether the alternatives were seriously considered or just listed for the appearance of rigor.

**No warnings or gotchas.** Real documentation says "watch out for X" and "don't try Y, even though it seems like it would work." AI describes the happy path because it hasn't been burned by the unhappy one. The absence of "this will bite you" sections is a strong signal that nobody with operational experience reviewed the content.

**Assumed expertise not everyone has.** The document casually drops terms like "ADF round-tripping" or "SPIFFE identity delegation" without definition, as if every reader is already knee-deep in the implementation. AI inherits the vocabulary of its prompt and its source material without considering whether the reader shares that context. A human author who knows their audience calibrates which terms need explanation and which don't. An AI author treats everything it read during generation as common knowledge.

**"We accept this trade-off" without a "we."** AI uses collective pronouns to justify design decisions it made alone. "We considered three alternatives and chose option A" reads like a team deliberation. If the document was written by one person and an AI, that "we" is performing a consensus that never happened. Real design decisions name who decided and why, or at least acknowledge the decision was a judgment call rather than a group conclusion.

## What to do about it

AI made writing cheap. It didn't make reading cheap. We accelerated the part that was already fast and shifted more load onto the part that was already the hardest.

A few practical steps:

**State your audience in the first paragraph.** "This document is for the platform team evaluating our authentication options." or "This is a reference document intended as context for coding agents working on the ingestion pipeline." One sentence changes how the reader (human or AI) approaches everything that follows.

**Cut before you send.** The question isn't "is this information correct?" The question is "does this reader need this information?" A 30-page document that could be eight pages with better prioritization respects the reader's time more than a longer one that covers everything and serves no one. It also respects yours: fewer pages mean fewer comments to respond to, fewer misunderstandings to clarify, and fewer rounds of review before the document can move forward.

**Add opinions.** If you've worked with the system, say what you'd recommend and why. If you haven't (and the AI drafted it from specs), say that too. "I haven't tested this configuration in production" is more useful than a confident-sounding recommendation nobody verified.

**Include warnings.** After the AI drafts a section, ask yourself: "what would go wrong if someone followed this exactly?" Add the answer. The gotchas are the highest-value content in any technical document, and they're the part AI can't write because it hasn't been burned.

**Be honest about the review level.** If you used AI to generate the document and only had time for a light pass, say so. "This document was AI-drafted and lightly reviewed. Please flag errors." That one sentence is more respectful than pretending you wrote and verified every word. Attribution tells the reader "AI helped write this." What readers also need to know is how carefully a human reviewed it. As I wrote in the [Know Your Limits](/know-your-limits/) post, honest self-assessment leads to better decisions than performed confidence.

AI can write the draft in minutes. The review that turns it into something worth reading takes longer, and there's no shortcut for it. Skip that step, and your readers will notice before you do.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
