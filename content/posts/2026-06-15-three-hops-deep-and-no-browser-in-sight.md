---
title: "Three Hops Deep and No Browser in Sight"
date: 2026-06-15
slug: "three-hops-deep-and-no-browser-in-sight"
description: "MCP handles client-to-server auth fine. The problem starts when the server needs your Google token and the agent asking for it is three hops deep with no browser in sight."
tags: ["ai", "security", "agents", "mcp", "context-engineering"]
keywords: ["MCP authentication", "OAuth agents", "token gap", "multi-agent consent", "MCP URL elicitation", "agentic IAM", "agent authorization", "AAuth"]
images: ["/images/three-hops-deep-and-no-browser-in-sight/og.png"]
license: "CC BY 4.0"
draft: true
---

You've seen this screen. If you use Claude Code or Cursor with MCP servers, you've clicked through it dozens of times. "Google MCP Server wants to access your Google Account." You review the scopes, click Allow, a token lands in your local config, and everything works.

Now imagine the agent that needs your Google Calendar isn't the one you're talking to. It's three agents deep in a multi-agent chain, running in a container with no browser and no way to show you a consent screen.

That's what this post is about.
<!--more-->

{{< figure src="/images/three-hops-deep-and-no-browser-in-sight/og.png" alt="Watercolor split-screen illustration. Left side labeled 'On Your Laptop': a sheep with glasses sitting at a desk, clicking 'Allow' on a consent screen. Right side labeled 'Three Hops Deep': three sheep standing in a dim barn filled with hay bales arranged like server racks, facing a padlocked door with no computer in sight." >}}

## Two tokens, two problems

MCP authentication handles the connection between your client and the MCP server well. The spec's [OAuth 2.1 flow](https://modelcontextprotocol.io/specification/draft/basic/authorization) works like standard OAuth: your client authenticates with the MCP server's authorization server, gets an access token, and sends it with every request. The server validates the token, serves the request, and holds no per-user state. Stateless. Each request carries its own bearer token.

The problem starts when the MCP server needs to call an external service on your behalf. The token your client sends authenticates you *to the MCP server*. When that server needs to read your Google Calendar, it needs a completely different token. One that Google issued, through Google's own consent flow.

On your laptop, this is invisible. The local MCP server opens your browser to Google's consent screen, you approve, and the server stores the token in `~/.mcp-auth` or a similar local path. One user, one browser, done.

In any other environment, this falls apart. You could have the user acquire a Google token out of band and pass it to the MCP server. But the MCP spec explicitly calls this [token passthrough an anti-pattern](https://modelcontextprotocol.io/specification/draft/basic/authorization): the server accepts a token it didn't issue, can't verify how it was obtained, and has no way to confirm the scope is appropriate.

If you've configured your identity provider (Keycloak, Entra ID) as a broker for Google, the plumbing can work. The user authenticates through your SSO, Keycloak redirects the browser to Google's consent screen, the user approves, and Google returns an authorization code. Keycloak exchanges that code for Google's access and refresh tokens and stores them. Later, the MCP server can use [token exchange](https://datatracker.ietf.org/doc/html/rfc8693) to get the stored Google token from Keycloak. The exchange mechanism works. The bottleneck is the consent event that has to happen first.

Consent doesn't scale across providers. If your agent chain needs Google Calendar, Microsoft Graph, and Slack, each provider requires its own browser redirect, its own consent screen, its own token. You can't batch them. The question is *when* to acquire these tokens. At onboarding ("connect your accounts"), you over-provision because you don't know which services the user will actually need. At first use, you need a browser. Mid-execution of an agent chain, you have neither.

This is the token gap. The infrastructure for moving tokens between systems exists. What's missing is a way to get the user in front of the right consent screen at the right time, especially when "the right time" turns out to be three agents deep in a chain that has no browser.

{{< figure src="/images/three-hops-deep-and-no-browser-in-sight/token-gap.png" alt="Diagram showing the token gap. On the left, the internal trust domain: Keycloak issues an MCP token to the User (Claude Code), who sends requests with the bearer token to the MCP Server. The MCP Server validates against Keycloak. On the right, the external trust domain: Google Calendar API. Between them, a dashed red arrow labeled 'needs Google token ???' marks the gap. Below, a dashed box shows the Google Consent Screen that would issue the token, but requires a browser redirect with no path from the MCP server." >}}

The token gap is really two problems that look like one. Credentials are the plumbing: getting a token that the external provider accepts. The token either exists or it doesn't, and the mechanisms for acquiring it (token exchange, vault lookup, gateway injection) are well understood. Consent is the human problem: the user deciding which scopes to grant, to which agent, for what purpose. No amount of infrastructure replaces that decision.

On a laptop, the consent screen handles both. You authenticate to Google and approve the scopes in the same flow. Once the MCP server moves off your laptop, these concerns separate. A system where agents hold technically valid tokens that nobody explicitly authorized for the current use isn't a security solution. It's a liability. Every pattern below solves the credential problem at a different level. The harder question is always consent.

## The known patterns

Christian Posta has been writing some of the clearest analysis of MCP security and agent authorization patterns. His [taxonomy of MCP authorization patterns for upstream API calls](https://blog.christianposta.com/mcp-authorization-patterns-upstream-api-calls/) maps the approaches people use to cross this gap. Rather than retread his analysis (go read it, it's worth your time), I'll summarize where each one breaks.

**Shared admin credential.** Give the MCP server a single credential for Google. Every user's request goes through the same account. Easiest to implement, worst for security: no per-user scoping, no audit trail tying actions to individuals, and a single credential whose compromise exposes everyone. The MCP spec [explicitly calls this an anti-pattern](https://modelcontextprotocol.io/specification/draft/basic/authorization). Don't do it.

**Credential passthrough.** The user acquires a Google token out of band and passes it to the MCP server. The spec flags this as an anti-pattern too. The server accepts tokens it didn't issue and can't validate. There's no proof the token came from a proper OAuth flow, no way to verify the scope matches what this server should have.

**SSO federation.** Use your identity provider's brokering capability (Keycloak's identity broker, Entra ID's external identities) to federate with Google. If the user has already linked their Google account through the IdP, this works without any browser interaction at request time. The IdP stores the Google tokens, and token exchange surfaces them to the MCP server. This solves the credential problem cleanly.

It doesn't solve the consent problem. When you configure Google as a broker in Keycloak, you specify which scopes to request up front: `openid`, `email`, `profile` for identity, plus whatever API scopes your MCP servers need (`calendar.readonly`, `drive.readonly`). These lock in at configuration time. If a new MCP server needs a scope you didn't anticipate, you update the config and send the user through Google's consent screen again. Google shows all scopes at once, so you can't incrementally add one without a new consent event. And token exchange hands over the full stored token with all granted scopes. There's no built-in way to give one MCP server `calendar.readonly` and another `drive.readonly` from the same token.

This is the pre-flight consent problem in infrastructure clothing: pre-configure scopes and hope they cover everything agents will need. When they don't, you need a browser. Two IETF drafts, [Identity Assertion Authorization Grant](https://datatracker.ietf.org/doc/draft-ietf-oauth-identity-chaining/) and [OAuth Identity Chaining Across Domains](https://datatracker.ietf.org/doc/draft-ietf-oauth-identity-chaining/), aim to enable cross-domain token exchange without per-provider consent flows. Neither is widely implemented yet.

**URL elicitation.** The MCP spec's [elicitation mechanism](https://modelcontextprotocol.io/seps/1036-url-mode-elicitation-for-secure-out-of-band-intera) (SEP-1036) has two modes. `form` handles in-band data entry where the response passes through the MCP client. `url` bypasses the client entirely. In URL mode, the MCP server sends a URL to the client, the client shows it to the user, the user opens it in a browser. That URL initiates a standard OAuth authorization flow with Google. The callback redirects back to the MCP server, which receives the authorization code and exchanges it for tokens server-side. The user just clicks a link and approves. Tokens never touch the client or the model.

This works for multiple users, since each completes their own consent flow and the server stores per-user tokens. But it makes the MCP server stateful: it now manages external token storage, refresh rotation, and revocation. And it still requires a user with a browser at the other end of the chain.

**Agent gateway.** A gateway sits in front of MCP servers, controlling who can access which servers and tools. Projects like [Kuadrant's MCP gateway](https://github.com/Kuadrant/mcp-gateway) enforce authN/authZ via JWT validation and CEL-based (Common Expression Language) policies at this layer. Christian's [Pattern 5](https://blog.christianposta.com/mcp-authorization-patterns-upstream-api-calls/#pattern-5-offload-out-of-band-elicitation-to-secure-infrastructure) extends this: the gateway also acquires and manages credentials for upstream APIs, injecting external tokens into outbound calls so the MCP server never touches them. But a gateway operates within the platform's trust domain. It can block access to an MCP server, but it can't downscope an already-granted Google token or make consent decisions on the user's behalf. Platform authorization and external-service consent are orthogonal.

Each of these patterns assumes something about the environment: that a user is present, that a browser is reachable, or that the credential-acquiring component knows which user to act for. Those assumptions hold on a developer laptop. They start failing when the MCP server runs remotely, in a cluster, or in any environment where no browser is directly reachable. They collapse entirely when agents call other agents.

## Where it gets harder: multi-agent chains

{{< figure src="/images/three-hops-deep-and-no-browser-in-sight/multi-agent-chain.png" alt="Diagram showing a multi-agent chain. User (Claude Code) with a browser sends 'schedule meeting' to a Planning Agent (hop 1, no browser), which sends 'find slots' to a Calendar Agent (hop 2, no browser), which sends 'read calendar' to a Google MCP Server (hop 3, no browser). The MCP Server needs a Google token to reach the Google Calendar API but has no path to the user's browser." >}}

Take a concrete scenario. A planning agent receives a request: "Schedule a meeting with the team and attach the latest design doc." The planning agent calls a calendar agent to find your available slots. The calendar agent calls a Google MCP server to read your calendar. That MCP server needs a Google OAuth token for your account.

You made the original request three hops ago. The Google MCP server has no connection to a browser. URL elicitation can't work because there's no client to show the URL to. The calendar agent doesn't even know it was invoked by a human. It just received a tool call from the planning agent.

Three approaches keep coming up. None of them work well.

{{< figure src="/images/three-hops-deep-and-no-browser-in-sight/error-propagation.png" alt="Two diagrams comparing error propagation approaches. Top (red, unreliable): -32042 error flows from MCP Server through LLM agents back to user, but may get lost or rephrased at each hop. Bottom (green, reliable): same error intercepted at the harness transport layer, propagated through infrastructure without the LLM seeing it." >}}

**Error propagation.** The MCP spec has a mechanism for direct connections: the Google MCP server returns error code `-32042` (`URLElicitationRequiredError`) with a consent URL embedded in the response. The client recognizes the error, shows the URL, the user completes the OAuth flow, the callback lands on the MCP server, and the client retries.

In a multi-agent chain, this falls apart. The error goes to the calendar agent, not to the user's client. For the consent URL to reach the user, every intermediate agent would need to recognize it and propagate it up the chain. LLM-based agents are unreliable at this. They might rephrase the error, attempt workarounds, or lose the URL entirely. Even if the URL reaches the user and they complete the consent flow, the "retry" signal needs to travel back down through the same chain.

A more promising approach would handle this at the harness level. The runtime that makes MCP calls intercepts the `-32042` at the transport layer before the LLM sees it, propagates the consent URL back through the infrastructure chain, and retries transparently once the user completes the flow. The LLM never sees the auth error. But this requires every harness in the chain to support the protocol, and no agent framework standardizes this today.

**Async notification.** Instead of propagating the consent URL through the agent chain, the MCP server delivers it via a side channel: email, Slack message, push notification. The user clicks the link, completes the same OAuth consent flow in their browser, and the callback lands on the MCP server just like in URL elicitation. The OAuth flow is identical. Only the delivery mechanism for the consent URL is different.

This decouples consent from the agent chain but introduces its own problems. The MCP server needs to know how to reach the user (email address? Slack handle?) and needs to identify which user to contact from the bearer token on the original request. Timeouts are ugly: the agent chain blocks while waiting, with no guarantee that consent ever arrives.

**Pre-flight consent.** Before the agent chain starts, the platform collects all the tokens the chain *might* need. The user consents to Google Calendar, Google Drive, Slack, and Jira up front. The platform stores tokens in a vault and injects them as needed.

This front-loads the UX problem but creates over-provisioning. The platform doesn't know which external services the chain will actually use because agent behavior is non-deterministic. Asking for every possible scope up front violates least privilege. Users learn to click "Allow" without reading the scopes, which is exactly the pattern OAuth was designed to prevent.

[CoSAI's Agentic IAM paper](https://www.coalitionforsecureai.org/wp-content/uploads/2026/04/agentic-identity-and-access-control.pdf) (March 2026) establishes the right principles for multi-agent delegation: scope narrows at each hop, never expands. Delegation tokens carry explicit actor and subject claims so the chain of custody stays auditable. These principles describe what the token *should look like* once it exists. Getting the user's consent in the first place, when the user is three hops away, is a different problem entirely.

The most interesting architectural proposal I've seen is [AAuth](https://aauth.dev), a delegation protocol from Dick Hardt (the author of OAuth 2.0) that rethinks the problem from scratch. It's an [IETF draft](https://datatracker.ietf.org/doc/draft-hardt-aauth-protocol/) in the OAuth working group. Instead of one-time consent grants that get reused indefinitely, AAuth introduces a Person Server that acts as an ongoing consent oracle. Dasith Wijesiriwardena's [errand analogy](https://dasith.me/2026/06/10/the-errand-agentic-delegation/) is the most accessible explanation, and Christian wrote a [hands-on demo walkthrough](https://blog.christianposta.com/aauth-full-demo/). The agent doesn't hold your Google token. It carries an unsigned request from the resource to the Person Server, the Person Server checks with you (or evaluates against a pre-approved "mission"), and returns a signed authorization. The Person Server evaluates each request individually. The agent shuttles tokens between parties but never holds standing credentials.

The "mission" concept is what makes this click. A mission is a written-down, approved intent that the Person Server holds on behalf of the user. Think of it as a scoped work order: "schedule a meeting with the team and attach the latest design doc." The agent proposes the mission, the user approves it, and every subsequent request gets evaluated against the mission's stated purpose. Read a calendar to find available slots? In scope, approved silently. Send an email to someone not on the team? Out of scope, escalated to the user.

The Person Server sees all requests across all resources under that mission, which makes it the one party positioned to detect when the agent's behavior drifts from the original intent. Missions have a lifecycle: active or terminated. Tokens issued under them are short-lived. That's a cleaner answer to the pre-flight consent problem than asking for every possible scope up front and hoping for the best.

AAuth also handles sub-agent chains explicitly. Each hop gets its own identity for audit and revocation, authority flows through the parent agent, and the full delegation chain back to the person is preserved. The protocol is early (the [spec](https://datatracker.ietf.org/doc/draft-hardt-aauth-protocol/), an [interactive explorer](https://explorer.aauth.dev/), and a .NET SDK are available), and the architecture addresses the right problems. It also makes the credentials-vs-consent split structural: the Person Server handles consent (did the user approve this action?), while the resource's Access Server enforces its own policies independently. Two gates, both must pass.

The catch: AAuth requires the resource to participate in the protocol. The Person Server issues AAuth tokens, not Google OAuth tokens. For existing providers like Google, Microsoft, or Slack that only accept their own OAuth tokens, you still need their consent flow to get a token they'll accept. AAuth solves consent and delegation for resources that speak AAuth. For everything else, the consent screen problem stays until major API providers adopt the protocol.

## What remains open

The token gap has patterns. Multi-agent consent doesn't. Here's what I think still needs solving.

**Where do tokens live?** Per-user external tokens need to persist across agent invocations but shouldn't be accessible to agents that don't need them. A vault with fine-grained access policies is the obvious answer, but the lifecycle is tricky. Who provisions the vault entry? Who rotates it? What happens when the user revokes consent through Google's security settings? Who cleans up the stale token?

**How do you reach the user?** In a multi-agent chain, the consent request needs to travel back to a human who can open a browser. Today this is ad hoc: error propagation, push notifications, Slack messages. There's no standard channel for "an agent three hops deep needs your approval." Building one means defining a consent backpropagation protocol that agent frameworks understand.

**What happens when consent drifts?** A user approves `calendar.readonly` for a scheduling task. Six months later, a different agent chain uses the same token to read calendar details for a completely different purpose. The token is technically valid. The consent is contextually stale. AAuth's mission model addresses this by scoping consent to a specific task with a defined lifecycle. But deciding what counts as "in scope" is left to the Person Server's policy engine, and that policy engine doesn't exist yet as a general-purpose solution. Of the open problems, this is the one that worries me most. A valid token with stale consent is indistinguishable from a properly authorized one until something goes wrong.

The [Vercel/Context.ai incident](https://thehackernews.com/2026/04/vercel-breach-tied-to-context-ai-hack.html) in April 2026 showed what happens when these problems aren't addressed. An infostealer on a Context.ai employee's machine compromised OAuth tokens that Context.ai held on behalf of its users. One of those tokens belonged to a Vercel employee who had connected Context.ai to their enterprise Google Workspace with broad permissions. The attacker used that token to access the employee's Google Workspace account, and from there found credentials that let them into Vercel's internal environments, including dashboards, API keys, and environment variables that weren't marked as sensitive. A single OAuth grant on a third-party AI tool became the first hop in a chain that reached deep into an enterprise. Every token in that chain was valid and every access was authorized, but the usage was not what anyone intended.

The IETF drafts on identity chaining and assertion grants are the right long-term direction. When they reach production implementations, they'll provide a standards-based way to exchange internal tokens for external ones without the user clicking through a consent screen every time. But "12-24 months to RFC" means organizations deploying multi-agent systems today need interim solutions.

The fundamental tension remains: agents are non-deterministic, but OAuth consent is interactive. Agents compose dynamically, but consent is granted statically. Protocols like [AAuth](https://aauth.dev) and standards like the IETF identity chaining drafts are attacking this from different angles, but neither is production-ready today. Until the consent model catches up to agent composition, the gap between "the agent has a valid token" and "the user approved this specific use" will keep growing.

On your laptop, that gap doesn't matter. Three hops deep and no browser in sight, it's the whole problem.

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
