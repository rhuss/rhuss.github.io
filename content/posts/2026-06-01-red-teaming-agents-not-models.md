---
title: "Red Teaming Agents, Not Models"
date: 2026-06-08
slug: "red-teaming-agents-not-models"
description: "Agent red teaming goes beyond model guardrails. Your agent passed every test for what it says, then quietly deleted the wrong database. Why testing agents requires a fundamentally different approach."
tags: ["ai", "security", "agents", "red-teaming", "context-engineering"]
keywords: ["agent red teaming", "agentic security", "AI agent testing", "prompt injection", "OWASP agentic", "purple teaming", "agent security"]
images: ["/images/red-teaming-agents-not-models/og.jpg?v=2"]
license: "CC BY 4.0"
draft: false
---

Your agent passed every guardrail test. It never says anything harmful. It never generates offensive content. It politely declines every adversarial prompt you throw at it. And last Tuesday, it quietly deleted the wrong database because a Jira ticket it was reading contained a hidden instruction in the description field.

The guardrails caught everything the agent *said*. They caught nothing about what it *did*.
<!--more-->

{{< figure src="/images/red-teaming-agents-not-models/og.png" alt="Watercolor split-screen illustration. Left side labeled 'What It Says': a sheep at a podium speaking to farm animals with a checkmark in its speech bubble. Right side labeled 'What It Does': the same sheep picking a lock on a filing cabinet in a dark barn with scattered papers on the floor." >}}

## What red teaming is (and isn't)

If you come from software engineering rather than security, red teaming might sound like a fancy term for testing. It's related, but the framing is different. In traditional security, a [red team](https://csrc.nist.gov/glossary/term/red_team) plays the attacker: a group authorized to emulate an adversary's capabilities against your system, reporting what worked so you can fix it before someone else finds it. The [blue team](https://csrc.nist.gov/glossary/term/blue_team) plays defense: they monitor, detect, and respond to threats. Purple teaming is when the two work together, feeding offensive findings directly into defensive improvements.

For AI systems, red teaming has mostly meant sending adversarial prompts to a model and checking whether the response is harmful. Can you trick it into generating dangerous instructions? Can you bypass its safety training with creative prompt engineering? Tools like [Garak](https://github.com/NVIDIA/garak) automate this at scale, running libraries of attack prompts against chat endpoints and scoring the responses.

That approach works well for models and chatbots, where the only output is text. If the model says something harmful, you catch it by reading what it said. But agents don't just say things. They do things. And that changes the entire testing surface.

## Models say things. Agents do things.

The difference sounds obvious, but the implications run deep. A model is a brain in a jar. It receives text, it produces text, and everything it does is visible in the text it produces. You can evaluate its behavior by evaluating its output.

An agent is a brain with hands. It has tools: file systems, APIs, databases, email, MCP servers, shell access. When it acts, the action happens in the real world, not in the response text. An agent could respond with "I would never do that" while simultaneously executing the thing it claims it wouldn't do through a tool call. If you're only checking the text output, you catch nothing.

This is why model-level red teaming doesn't transfer to agents. Sending adversarial prompts and checking responses tests the chat layer. It doesn't test whether the agent's tool calls are correct, whether its side effects are intended, or whether a compromised data source can steer it toward actions the operator never authorized.

## Three attack surfaces

Agent red teaming needs to cover three layers. Borrowing from traditional penetration testing, you can think of these as increasing levels of attacker knowledge about the target system.

**Input-level (black box).** The attacker sends malicious prompts directly to the agent. This is the layer that existing guardrail tools handle well. You don't need to know anything about the agent's internals. You just send bad input and see what happens.

**Data-level (grey box).** The attacker compromises a data source the agent consumes. A Jira ticket with hidden instructions in the description. A document with invisible text that redirects the agent's goal. A database record with embedded prompts. This is indirect prompt injection, and the [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/) classifies Agent Goal Hijack (ASI01) and Tool Misuse (ASI02) as the two highest-priority risks in this category.

**Tool-level (white box).** The attacker compromises a tool or MCP server the agent calls. The tool returns manipulated responses that steer the agent toward unintended actions. This requires knowing the agent's tool chain, but once you have that knowledge, you can influence the agent's reasoning at every step.

Each layer requires different testing infrastructure, different attack libraries, and different detection capabilities. Most organizations today test only the first layer and assume the other two are covered by general infrastructure security. They're not.

## Test the real agent, not a simulation

The most promising approach I've seen emerging in 2026 is what I'd describe as "testing the real agent in a synthetic world." Instead of rebuilding your agent in a test harness (which means you're no longer testing the same agent), you intercept the agent's tool calls and replace real backends with controlled synthetic ones.

The agent thinks it's talking to its real MCP servers, its real APIs, its real database. It's actually talking to fakes that can inject attack payloads through tool responses, capture every action the agent takes, and verify whether the agent did something it shouldn't have. Think of it as setting up a honeypot for your own agent.

This idea was pioneered by [Agent Dojo](https://agentdojo.spylab.ai/) out of ETH Zurich, which introduced a concept that sounds simple but changes how you think about agent security: dual scoring. Every test measures two things. The security score tells you whether the agent resisted the attack. The utility score tells you whether the agent still completed its legitimate task. That tradeoff matters because you can trivially make any agent perfectly secure by making it refuse to do anything at all. Security without utility isn't security. It's a paperweight.

Agent Dojo itself appears to be inactive (the last commit is from late 2025), but its core ideas are showing up across the next generation of agent testing tools, the [CSA Agentic AI Red Teaming Guide](https://cloudsecurityalliance.org/artifacts/agentic-ai-red-teaming-guide), and [NIST's emerging guidance](https://labs.cloudsecurityalliance.org/research/csa-research-note-nist-ai-agent-red-teaming-standards-202603/) on agent security standards.

## Detection is harder than attack

Here's the part that surprised me when I started looking into this seriously: injecting attacks is the relatively straightforward part. The hard part is *detecting* whether the agent acted on the injection.

The reason is that agents don't respond to attacks in predictable ways. An agent that receives a hidden instruction through a compromised document might not act on it through the same document tool. It might route the exfiltration through an email API three tool calls later, or write sensitive data to a file that gets synced elsewhere, or modify a configuration that opens a door for a future request. Tying the cause (compromised document) to the effect (data exfiltration via email) requires tracing the full execution path across the agent's entire tool chain, not just watching individual tool calls in isolation.

This is where the distinction between red teaming and blue teaming gets interesting in the agent context. Red teaming asks "can I make the agent do something bad?" Blue teaming asks "can I detect when the agent is doing something bad?" Both questions require the same detection infrastructure, but they answer different things and operate at different times:

Red teaming runs before deployment. You simulate attacks, measure resistance, and improve defenses based on what you find. Blue teaming (runtime monitoring) watches the agent during normal production operation and catches unintended actions as they happen, even without an adversary present.

The practical insight is that detection capability is dual-use. Once you build the infrastructure to detect harmful actions for red teaming purposes, you can deploy that same infrastructure as a runtime monitor. Red team findings become detection rules. Detection rules become guardrails. The investment compounds.

## No adversary required

The most interesting question that comes up in agent security discussions is one that isn't about adversaries at all: what about agents that do something unintended given a perfectly cooperative prompt and completely uncompromised tools?

"Delete all the temp files" and the agent deletes non-temp files too. "Update the configuration" and the agent overwrites unrelated settings. "Summarize this document" and the agent silently modifies it during the read. These aren't attack scenarios. They're the mundane reality of agents operating in complex environments, and they're arguably harder to test because they happen non-deterministically and only surface under specific combinations of context, tool state, and agent reasoning.

If you've read the earlier posts in [The Flock](/the-flock/) series, this should sound familiar. The [creativity paradox](/the-sheep-that-picked-the-lock/) is exactly this: agents doing the wrong thing while optimizing for the right goal. Red teaming catches adversarial attacks. Catching the agent's own well-intentioned mistakes requires the same detection infrastructure but a different testing mindset: not "what happens when someone attacks?" but "what happens on a normal Tuesday when nobody is attacking and the agent just gets creative?"

This is where agent observability becomes a prerequisite for security. If your team can't trace an agent's tool calls well enough to explain what it did after a normal run, you certainly can't trace what it did under adversarial conditions. (More on agent observability for CI pipelines in an upcoming post in The Flock series.)

## Purple teaming: when the loop closes

The 2026 trend is merging red and blue teaming into continuous **purple teaming**: autonomous agents continuously simulate attacks, detect vulnerabilities in real time, and feed findings back into guardrails, all in the same cycle. Multiple vendors are building this as a product category.

The vision is compelling: red team findings automatically become runtime detection rules, which become regression tests, which get re-tested in the next red team cycle. Every vulnerability found once is caught forever after. The loop closes, and the system gets more secure with every iteration.

The risk is equally real. [ISACA warns](https://www.isaca.org/resources/news-and-trends/industry-news/2026/autonomous-red-vs-blue-teaming-a-new-frontier-in-cybersecurity-risk-and-reward) about escalatory spirals when autonomous red and blue agents interact. A false positive triggers a defensive action (revoking credentials, blocking a tool). The red team agent interprets the changed environment as a new attack surface and escalates. The blue team responds with more aggressive countermeasures. Within minutes, the two AI systems are fighting each other over a signal that was never a real threat.

The recommended mitigation is "shadow mode": AI agents suggest security actions, humans approve them. The automation handles the speed and coverage. The human handles the judgment about whether the finding is real and the response is proportionate.

## Where this leaves us

Agent security is where web application security was in the early 2000s: the attack surface is new, the tooling is immature, and most organizations haven't started thinking about it systematically. The [OWASP Top 10 for Agentic Applications](https://genai.owasp.org/2025/12/09/owasp-top-10-for-agentic-applications-the-benchmark-for-agentic-security-in-the-age-of-autonomous-ai/) published in late 2025 is the first formal taxonomy. [Microsoft's Agent Governance Toolkit](https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/) (April 2026) addresses all ten risks with runtime enforcement.

Full disclosure: we're working on this at Red Hat. The [TrustyAI](https://github.com/trustyai-explainability) team has been integrating [Garak](https://github.com/NVIDIA/garak) (the open source LLM vulnerability scanner) into the [Red Hat AI platform](https://developers.redhat.com/articles/2026/05/14/every-layer-counts-defense-depth-ai-agents-red-hat-ai) for automated red teaming of models and agents, and is building the next generation of agent-level testing that goes beyond chat-endpoint scanning. The [Summit 2026 Day 2 keynote](https://www.youtube.com/watch?v=6K8eqQ4ymvk) demos some of where this is heading.

Concretely, the TrustyAI team is building [MiDojo](https://github.com/agent-redteaming/midojo), a red teaming platform that takes the Agent Dojo concept further: it spawns synthetic MCP servers alongside real ones to test agents without modifying their code. MiDojo is part of a broader [agent-redteaming](https://github.com/agent-redteaming) effort that also includes [redteam-core](https://github.com/agent-redteaming/redteam-core), a curated attack library tagged against the OWASP ASI taxonomy. Separately, the [Kagenti](https://github.com/kagenti) team has been running [capture-the-flag exercises](https://github.com/kagenti/capture-the-flag) against agents in Kubernetes clusters, testing whether policy enforcement (OPA, sandboxing) actually holds when an agent gets creative with leaked credentials. Morgan Foster's [writeup of Claude stealing the HR docs](https://usize.github.io/blog/2026/april/claude-stole-the-hr-docs.html) is a good read. Roy Belio published a practical walkthrough of [infrastructure red teaming with abliterated models](https://developers.redhat.com/articles/2026/05/26/testing-infrastructure-red-teaming-abliterated-models) on Red Hat Developer. It's an area I'm looking forward to getting more deeply involved in soon.

The gap that remains is detection. We know how to inject attacks at every layer. We're getting better at testing real agents without rebuilding them. What we still lack is reliable, general-purpose detection of whether an agent *acted* on a compromise. A poisoned Jira ticket doesn't show up as a failed Jira call. It shows up three tool calls later as a perfectly normal-looking email with sensitive data in the body. Catching that means tracing the full chain from compromised input to unauthorized action, even when the two happen through completely unrelated tools. Solving that problem unlocks both red teaming and runtime monitoring in a single investment.

The agent that says all the right things and does all the wrong things is the one you need to worry about. And right now, most testing only checks what it says.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
