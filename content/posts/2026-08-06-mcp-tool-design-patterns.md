---
title: "Your API Is Not Your MCP Tool"
date: 2026-08-06
slug: "mcp-tool-design-patterns"
description: "How to design MCP tools that agents actually use well. Tool count, parameter naming, enums over booleans, context hygiene, and what the 2026-07-28 spec changes for tool definitions."
tags: ["mcp", "context-engineering", "ai", "api-design"]
keywords: ["MCP", "Model Context Protocol", "tool design", "context engineering", "API design", "LLM tools", "MCP server", "tool granularity", "parameter design"]
images: ["/images/mcp-tool-design-patterns/og.png"]
draft: false
license: "CC BY 4.0"
---

{{< figure src="/images/mcp-tool-design-patterns/og.png" alt="Retro-technical illustration of a 1950s telephone switchboard room. On the left, a large board with tangled cables filling every jack, labels buried under the mess. A switchboard operator in 1950s attire sits between two panels, one hand gesturing at the chaos, the other holding a cable toward a clean panel on the right. The clean panel has eight clearly labeled jacks with city names (London, Paris, New York, Berlin), green indicator lights glowing beside each one, cables hanging in neat parallel lines." >}}

The most natural thing to do when building an MCP server is to mirror your existing API. You have a REST endpoint for creating users, so you make a `create_user` tool. You have one for listing orders, so you make a `list_orders` tool. Fifteen endpoints become fifteen tools, each one a thin wrapper that translates JSON-RPC to HTTP and passes the response back.

It works. The agent can call the tools, the tools return data, and everything looks fine in your test harness. Then you connect it to a real conversation with twenty other MCP servers loaded, and the agent starts picking the wrong tools, hallucinating parameter values, and burning half its context window on tool definitions it never uses.
<!--more-->

The problem isn't MCP. The problem is that APIs were designed for a fundamentally different consumer. A developer reads documentation, bookmarks the three endpoints they need, and writes code that calls them in the right order with the right parameters. An LLM sees every tool definition at once, every parameter description, every schema. It has to pick the right tool from that pile on every turn, and each definition costs tokens whether the tool gets called or not.

Anthropic's engineering team [put it directly](https://www.anthropic.com/engineering/writing-tools-for-agents): "A common error we've observed is tools that merely wrap existing software functionality or API endpoints." AWS [frames the same insight](https://aws.amazon.com/blogs/machine-learning/mcp-tool-design-practical-approaches-and-tradeoffs/) as two failure modes: "bloat" (tool definitions consuming context on every call whether used or not) and "confusion" (models picking wrong tools as context fills). Both companies arrived at the same conclusion from different directions. MCP tool design is not an API design problem. It's a [context engineering](/context-engineering-101/) problem.

## How many tools is too many

There's no single number, but the data points tell a consistent story.

[Tool-selection accuracy drops below 90%](https://arxiv.org/abs/2606.30317) between 10 and 15 tools for Claude Haiku 4.5, and between 20 and 30 tools for Sonnet 4. Bigger models tolerate more tools, but none of them are immune. GitHub's MCP server [grew to over 100 tools](https://www.zenml.io/llmops-database/building-and-scaling-a-production-mcp-server-for-developer-tooling) after a month of community contributions, degraded agent capabilities, and got cut back to about 40.

The pattern is the same in every case: teams start by exposing everything, then discover that more tools means worse results. The reduction isn't about removing functionality. It's about consolidating related operations into higher-level tools that match what users actually ask for.

Consider a project management API with separate endpoints for creating issues, assigning them, setting priority, adding labels, and linking to epics. That's five tool definitions in the context window and a workflow that requires the agent to sequence five calls correctly. A single `manage_issue` tool that accepts an action parameter and handles the orchestration internally gives the model one decision point instead of five. The agent's job becomes "pick the right tool" rather than "pick the right five tools in the right order."

AWS [calls this the progression](https://aws.amazon.com/blogs/machine-learning/mcp-tool-design-practical-approaches-and-tradeoffs/) from V1 (raw API passthrough) through V6 (agent-as-tool), and their conclusion is worth quoting: no single version wins across all dimensions. Raw passthrough is easiest to build but hardest for agents to use. Fully orchestrated tools are great for agents but expensive to maintain. The right level depends on how complex the workflow is and how often the agent needs fine-grained control over individual steps.

The per-server tool count is only half the equation. In any real setup, you're connecting multiple MCP servers at once, and their tool definitions stack. Every server you add pushes more definitions into the context window. Being selective about which servers you connect matters at least as much as being selective about which tools each server exposes.

Claude Code's configuration hierarchy helps with this on the client side. You define MCP servers at user, project, or directory scope, with project-level configs overriding what's active for a specific codebase. A Kubernetes project gets your cluster tools, a documentation project gets your writing tools, and nothing bleeds across. [cc-setup](https://github.com/cc-deck/cc-setup) wraps this in a terminal UI for managing servers, permissions, and plugins per project from a central registry.

## Parameters that help instead of confuse

The number of parameters matters almost as much as the number of tools. AWS [recommends](https://docs.aws.amazon.com/prescriptive-guidance/latest/mcp-strategies/) roughly eight or fewer per tool, with an important caveat: if bundling related operations requires more than eight parameters, prioritize the bundling over the parameter count. A single tool with twelve well-described parameters usually outperforms three tools with four parameters each, because the model makes one tool-selection decision instead of three.

But parameter count is the easy part. The harder lesson is that parameter naming and typing should optimize for LLM comprehension, not for your internal data model.

**Rename parameters to match how users think.** If your API takes `org_id`, but users say "my company," name the parameter `organization_name` and resolve the ID internally. The model generates parameter values from the conversation context, and the conversation uses human language, not database identifiers.

**Use semantic identifiers, not UUIDs.** This one surprised me. BoundaryML [ran benchmarks](https://www.boundaryml.com/blog/uuid-swap) comparing UUID-based tool parameters against integer-remapped alternatives. The result: 48.5 average errors per session with UUIDs versus 5.5 with integer remapping. Arbitrary alphanumeric strings give models nothing to reason about, and they hallucinate plausible-looking IDs that don't exist. If your tool needs to reference an entity, resolve the UUID to a human-readable name or a simple index before the model ever sees it.

Every MCP tool defines its parameters using [JSON Schema](https://json-schema.org/) in the `inputSchema` field. The client sends that schema to the LLM as part of the tool definition on every invocation, so the model sees the full parameter structure, types, descriptions, and constraints before deciding how to call the tool. With the [2026-07-28 spec](https://modelcontextprotocol.io/specification/2026-07-28/server/tools), `inputSchema` supports full JSON Schema 2020-12, including `oneOf`, `anyOf`, conditionals, and `$ref`, so you can express complex parameter relationships directly in the schema.

**Use enums over booleans.** JSON Schema's `enum` keyword lets you list the exact valid values inline, and the model uses those values directly when generating its tool call. A parameter like `include_archived: true` forces the model to infer what true means in this specific context. `filter: "active"` or `filter: "all"` gives the model unambiguous options to pick from. AWS Prescriptive Guidance [recommends enums](https://docs.aws.amazon.com/prescriptive-guidance/latest/mcp-strategies/mcp-tool-strategy-definitions.html) for any finite set of values: "use enums for parameter values to make it easy for the LLM to select the correct options." Booleans optimize for code execution, enums optimize for LLM reasoning.

**Add a response format parameter.** Anthropic [found](https://www.anthropic.com/engineering/writing-tools-for-agents) that adding a `response_format` parameter with options like "concise" and "detailed" reduced token usage by roughly two-thirds for their Slack integration (72 tokens for concise versus 206 for detailed). The model doesn't always need the full response, and giving it a way to say so saves context for the rest of the conversation.

**Tool naming has measurable effects.** In the [same post](https://www.anthropic.com/engineering/writing-tools-for-agents), Anthropic tested prefix-based (`slack_list_channels`) versus suffix-based (`list_channels_slack`) namespacing and found measurable differences on their tool-use evaluations. The effects varied by model, which means the right naming convention depends on which LLM your users run. If you're building a public MCP server, test both patterns against the models you care about. Assumptions about naming are surprisingly unreliable.

## Context hygiene for tool definitions

Each tool definition [costs somewhere between 100 and 1,000 tokens](https://github.com/modelcontextprotocol/modelcontextprotocol/discussions/2812), depending on schema complexity. AWS Prescriptive Guidance [puts it at](https://docs.aws.amazon.com/prescriptive-guidance/latest/mcp-strategies/) 5,000 to 10,000 tokens for just 20 tools. With 50 tools loaded, that's 20,000 to 25,000 tokens consumed before the first message in the conversation. On a 32K context window, that's most of the available space. Even on larger windows, those tokens compete with conversation history, file contents, and everything else the agent needs to reason about.

The MCP specification now includes primitives for managing this.

**Deterministic tool ordering** is the simplest win. The [2026-07-28 spec](https://modelcontextprotocol.io/specification/2026-07-28/server/tools) recommends that servers return tools from `tools/list` in a deterministic order. This matters because LLM providers cache the prompt prefix. If tool definitions appear in the same order across requests, the cached prefix covers them and the provider skips re-processing. Randomized ordering breaks the cache on every call.

**CacheableResult** lets servers attach `ttlMs` and `cacheScope` fields to list and read results, so clients know how long they can cache a response without re-polling. If your tool list doesn't change during a session, setting a long TTL means the client asks once and remembers.

**Progressive tool loading** goes further. Instead of registering full tool definitions at startup, register only metadata (name and one-line summary) and load the full schema on demand when the agent actually wants to call a tool. Claude Code's [ToolSearch](https://www.anthropic.com/engineering/advanced-tool-use) mechanism works this way, and the token savings are substantial. The tradeoff is that the agent has less information for initial tool-selection, so the summaries need to be precise enough for the model to pick correctly from the short descriptions alone.

**[subscriptions/listen](https://modelcontextprotocol.io/specification/2026-07-28/server/utilities/subscriptions)** is the new unified mechanism for change notifications. If your server adds or removes tools at runtime, it can push change notifications through a single long-lived stream rather than requiring clients to poll `tools/list` on every turn.

These are infrastructure-level optimizations, and they matter most for MCP servers with large tool sets or deployments where multiple servers connect to the same client. But even a small server benefits from deterministic ordering and accurate tool descriptions, because every wasted token is a token the agent could have spent on reasoning.[^spec]

[^spec]: The [2026-07-28 MCP specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/) also brings a [stateless protocol core](https://modelcontextprotocol.io/specification/2026-07-28/basic/lifecycle), [Multi Round-Trip Requests](https://blog.modelcontextprotocol.io/posts/2026-07-28/#multi-round-trip-requests-mrtr) for tools that need user input mid-execution, and [deprecations](https://blog.modelcontextprotocol.io/posts/2026-07-28/#deprecations) of Roots, Sampling, and Logging.

## What this means in practice

The central tension in MCP tool design is that everything you expose costs context, and context is the scarce resource that determines whether the agent works well or poorly. Every tool, every parameter, every line in a description competes for the same budget.

The teams that got this right didn't remove functionality. They redesigned the interface between the API and the agent: consolidating fine-grained operations into higher-level tools that match user intent, renaming parameters to match how people talk about the domain, replacing UUIDs with meaningful identifiers and booleans with enums.

None of this requires changes to the underlying API. The API serves its original consumers just fine. The MCP server is a translation layer, and the quality of that translation determines whether the agent is helpful or frustrating. Treating the API surface as the tool surface is the mistake. Designing for what the model sees, not for what the code does, is the fix.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
