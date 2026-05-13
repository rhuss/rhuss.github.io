---
title: "Know Your Limits: Quiz Yourself Before You Trust AI"
date: 2026-05-13
slug: "know-your-limits"
description: "AI can carry you into domains you can't verify. A self-assessment quiz reveals where your expertise ends. Finding that limit is the point."
tags: ["ai", "process", "opinion", "self-assessment", "context-engineering"]
keywords: ["AI trust calibration", "self-assessment AI", "developer AI trust", "AI verification", "LLM trust", "know your limits AI", "cognitive offloading AI"]
images: ["/images/know-your-limits/og.png"]
license: "CC BY 4.0"
draft: false
---

The conversation was going well. We were working out how to integrate [OpenShell](https://github.com/NVIDIA/OpenShell)'s network isolation into our agent platform. The AI had produced an overlap analysis, identified shared capabilities, proposed a feature breakdown for the integration. Everything sounded reasonable, the trade-offs clearly articulated, the architecture diagrams sensible. I was nodding along, ready to take the recommendation to the team.

Then a small voice in the back of my head asked: do you actually know enough about veth pairs and TLS MITM proxying to tell whether any of this is correct?
<!--more-->

{{< figure src="/images/know-your-limits/og.png" alt="Watercolor illustration of a sheep sitting at a small wooden desk in a meadow, taking a quiz with a pencil in its hoof. A chalkboard behind it shows a complex network diagram. Other sheep graze in the background, one wearing tiny reading glasses." >}}

## The comfort zone trap

When you use AI for technical architecture or feature evaluation, the conversation flows naturally. The AI explains trade-offs, proposes designs, writes implementation plans. Everything sounds plausible, because LLMs are exceptionally good at producing plausible-sounding output. That's what they're optimized for.

But plausible isn't correct, and you can only tell the difference within your own domain expertise. Shaping context helps the AI produce better output (that's what the [101 post](/context-engineering-101/) covered). This post is about a different problem: what happens when the output is good, maybe even correct, but you lack the expertise to verify it?

The risk isn't that AI gets it wrong. The risk is that you can't tell when it does. And [research from Aalto University](https://www.psypost.org/users-of-generative-ai-struggle-to-accurately-assess-their-own-competence/) suggests the problem is worse than we think: when interacting with AI tools, everyone overestimates their performance, regardless of skill level. Higher AI literacy correlates with *more* overconfidence, not less, because users trust the system's output without checking whether they could have reached the same conclusion on their own.

[Stack Overflow's 2025 developer survey](https://stackoverflow.blog/2026/02/18/closing-the-developer-ai-trust-gap/) found a matching paradox: 84% of developers use or plan to use AI tools, but only 29% trust them, down 11 percentage points from 2024. Developers know they should verify. The problem is they don't have a fast way to assess whether they're *capable* of verifying in a given domain.

## The five-minute honesty check

Here's a technique that takes about five minutes and reliably reveals where your expertise ends. When AI drives you into unfamiliar territory, ask it to generate a quiz. Five questions, four answers each, targeting the specific skills you'd need to implement or review the thing being proposed.

The prompt is straightforward. Here's the shape of what I used:

> We've just analyzed [project]'s [capability] and how it overlaps with our platform. My concern is that integrating this goes deeper into [domain] than our team's expertise. Create a quiz with 4-5 tough multiple-choice questions targeting the underlying concepts we'd need to understand. Don't test [project]-specific internals, test whether we understand the fundamentals it builds on. Include a scoring rubric that maps scores to actionable team decisions.

The quiz isn't a certification. It's a mirror. If you score 2 out of 5, you now know something important: you're past the boundary where you can meaningfully review AI output in this domain. And knowing that is the whole point.

## What the quiz actually reveals

We ran this during the [OpenShell](https://github.com/NVIDIA/OpenShell) evaluation. The AI generated four questions targeting the exact features the team would need to implement: veth pairs for container networking, `/proc`-based process inspection, TLS MITM proxying for traffic analysis, and SSRF hardening for outbound request filtering. (The full quiz is in the [appendix](#appendix-the-actual-quiz) if you want to try it yourself.)

The questions themselves were informative even before we answered them. One walked through setting up a network namespace with a veth pair, configuring IP addresses and routes, and then asked why the agent still can't reach the proxy. I didn't just get the answer wrong, I wasn't confident about what a veth pair even does in this context, and that gap in understanding is itself useful information. If the question doesn't make sense to you, you've found a boundary.

Wrong answers reveal something different: misconceptions. Good quiz questions have plausible distractors. If you pick one confidently and it's wrong, you've found a blind spot, a place where you think you know more than you do. Those blind spots are more dangerous than the things you know you don't know, because they're where you'll accept bad AI output without questioning it.

The quiz didn't tell us whether our integration approach was sound. It told us whether we could evaluate that question ourselves. The quiz doesn't test whether the AI is right. It tests whether *you* can tell if the AI is right.

## It's OK to hit your limit

This is the cultural part, and it matters as much as the technique itself. Hitting your limit on the quiz is the desired outcome. The purpose isn't to prove you're smart enough to review every AI recommendation. It's to find the boundary so you can make honest decisions about what happens next.

"We need a networking expert for this part" is a better outcome than shipping code nobody on the team can debug. "This evaluation looks reasonable but I can't verify the TLS interception claims, so let's get a second opinion before committing" is a better decision than nodding along because the trade-off analysis sounded convincing.

The quiz gives you a concrete, defensible reason to slow down. Instead of a vague feeling that you might be out of your depth (which is easy to dismiss), you have a score. You answered 1 out of 4 on the networking quiz. That's not a feeling. That's a measurement.

Sometimes the quiz tells you the opposite: you *do* know enough. You answer 4 out of 5, and the one you missed was a genuine edge case, not a fundamental gap. That confirmation is just as valuable, because it means your review of the AI's output is informed, not performative. Either way, you're making decisions based on measurement rather than assumption.

## When to reach for this

Not every AI conversation needs a quiz. The technique is most useful at specific moments:

- **AI proposes adopting a library or pattern you haven't worked with.** The analysis sounds good, but you've never actually used the thing being recommended. Quiz yourself on the concepts you'd need to maintain it.

- **A technical evaluation pushes into unfamiliar territory.** You started evaluating a feature and ended up discussing kernel capabilities or cryptographic protocols. If the conversation has moved beyond your comfort zone, the quiz will confirm it.

- **You catch yourself skimming AI-generated code.** This one is subtle. If you're reviewing code and you notice you're reading it like prose rather than tracing the logic, you might not have the domain knowledge to review it properly. A quick quiz on the underlying concepts will tell you.

- **A decision depends on expertise you're not sure you have.** The AI produced a recommendation. You're about to share it with the team. Before you do, spend five minutes checking whether you can defend it under questioning.

## Appendix: the actual quiz

This is the quiz we generated using [the prompt above](#the-five-minute-honesty-check) during the OpenShell integration evaluation. It was produced entirely by AI, targeting the underlying Linux networking concepts the team would need to understand. Try it yourself before reading the answers.

---

**Question 1: Network namespace isolation (veth pairs)**

You need to create an isolated network namespace for an agent process and connect it to the supervisor via a veth pair. The agent should only be able to reach the proxy at 10.200.0.1:3128. After creating the netns and veth pair, you configure the agent-side interface with `ip addr add 10.200.0.2/24 dev veth-s` and add `ip route add default via 10.200.0.1`. The agent still cannot reach the proxy. What did you forget?

- A) You need to run `ip link set veth-s up` and `ip link set veth-h up` to bring both ends of the veth pair to an operational state
- B) You need to add an iptables MASQUERADE rule on the supervisor side so the proxy can NAT the agent's traffic
- C) You need to set `net.ipv4.ip_forward=1` on the supervisor's namespace and add a FORWARD chain rule allowing traffic from the veth-h interface
- D) You need to create a bridge device and attach both the veth-h end and the supervisor's eth0 to it

---

**Question 2: Identifying which process initiated an outbound connection**

Your egress proxy intercepts a CONNECT request on source port 48372. You need to determine which binary on the system initiated this connection, so you can apply per-binary network policies. Using only the Linux `/proc` filesystem (no eBPF, no LD_PRELOAD), what is the correct sequence of lookups?

- A) Read `/proc/net/tcp` to find the socket inode for source port 48372, scan `/proc/*/fd/` symlinks to find which PID owns that inode, then `readlink /proc/<pid>/exe` to identify the binary
- B) Read `/proc/net/tcp` to find the destination IP, look up the IP in `/proc/*/net/route` to find the owning PID, then read `/proc/<pid>/cmdline` for the binary path
- C) Scan `/proc/*/net/tcp` per process to find which process has source port 48372 in its network namespace, then read `/proc/<pid>/exe`
- D) Read `/proc/net/tcp6` to get the socket's UID field, map the UID to a username via `/etc/passwd`, then find all processes owned by that user in `/proc/*/status`

---

**Question 3: TLS MITM for L7 inspection**

You want to add HTTP method/path level inspection to the proxy (e.g., allow GET but block POST to api.github.com). Since GitHub uses HTTPS, you need to TLS-terminate the connection. The agent sends `CONNECT api.github.com:443`. Your proxy needs to inspect the HTTP request inside the TLS tunnel. What is the correct sequence of operations?

- A) Accept the CONNECT, return 200, generate an ephemeral certificate for api.github.com signed by a sandbox-local CA, TLS-accept from the agent using that cert, parse the plaintext HTTP request, evaluate the OPA policy, then open a new TLS connection to the real api.github.com and relay
- B) Accept the CONNECT, open a TLS connection to the real api.github.com, perform the TLS handshake with GitHub, extract GitHub's certificate, re-sign it with the sandbox CA, then present the re-signed cert to the agent and relay all traffic bidirectionally
- C) Accept the CONNECT, return 200, then passively read the TLS ClientHello from the agent to extract the SNI field, use the SNI to make the policy decision without decrypting the traffic
- D) Reject the CONNECT, redirect the agent to an HTTP (non-TLS) version of the proxy endpoint where the request can be inspected in plaintext, then the proxy initiates the real HTTPS connection to GitHub

---

**Question 4: SSRF protection and DNS rebinding**

Your proxy blocks connections to internal IPs (RFC 1918, loopback, link-local, cloud metadata 169.254.169.254). The agent sends `CONNECT attacker.com:443`. Your proxy resolves attacker.com to 203.0.113.50 (a public IP), passes the SSRF check, and opens a TCP connection. However, the attacker's DNS server is configured with a 0-second TTL. By the time the TLS handshake completes, DNS resolves attacker.com to 169.254.169.254 (the cloud metadata service). The attacker's server never completes the TLS handshake, and the agent's HTTP library retries, this time resolving to the metadata endpoint. What is the correct mitigation?

- A) Pin the DNS resolution at the proxy level: resolve once, connect to that IP, and never re-resolve for the lifetime of the connection
- B) Add the resolved IP address to the TLS SNI extension so the upstream server must prove it controls that IP
- C) Set a minimum TTL floor of 60 seconds in the proxy's DNS resolver cache, ignoring the server's 0-second TTL
- D) Perform the SSRF check twice: once after DNS resolution and once after the TCP connection is established by checking `getpeername()` on the connected socket

---

**Scoring**

| Score | Assessment |
|-------|-----------|
| 4/4 | Team has deep networking chops. OpenShell-style features are realistic. |
| 3/4 | Solid foundation, but edge cases will slow you down. |
| 2/4 | Significant ramp-up needed. Budget for research spikes before committing. |
| 0-1/4 | The team needs networking expertise (hire or partner) before attempting this. |

<details>
<summary><strong>Show answers</strong></summary>

<p><strong>Q1: A.</strong> Newly created veth interfaces default to DOWN state. Both ends must be explicitly brought up with <code>ip link set ... up</code>. B and C would be needed for kernel-level IP forwarding, but OpenShell routes all traffic through an HTTP CONNECT proxy (application-level), not through kernel routing.</p>

<p><strong>Q2: A.</strong> The standard <code>/proc</code> lookup chain is: parse <code>/proc/net/tcp</code> to find the inode for the source port, scan <code>/proc/*/fd/</code> symlinks to find which PID holds that inode, then <code>readlink /proc/&lt;pid&gt;/exe</code> to get the binary path. B is wrong because <code>/proc/*/net/route</code> doesn't map to individual connections. C would work in theory but is expensive (scanning every process's network namespace). D only gives you the user, not the specific binary.</p>

<p><strong>Q3: A.</strong> This is the standard TLS MITM approach. The proxy generates a per-hostname ephemeral certificate signed by a CA that the agent's trust store accepts. Between the two independent TLS endpoints, the proxy sees plaintext HTTP and can inspect method, path, headers, and body. C only gives you domain-level filtering (which is what a Squid proxy already does via SNI).</p>

<p><strong>Q4: D.</strong> The most reliable mitigation is checking the actual connected IP via <code>getpeername()</code> after the TCP handshake succeeds, not just the resolved IP before connecting. This catches DNS rebinding regardless of caching behavior. A (DNS pinning) helps but doesn't cover all rebinding variants (e.g., dual-stack responses). Note: OpenShell currently does NOT implement DNS rebinding protection. The security audit flagged this as a gap.</p>

</details>

<div class="ai-attribution">

Author: Roland Huß [AIA HAb CeNc Hin R Claude Opus 4.6 v1.0](https://aiattribution.github.io/statements/AIA-HAb-CeNc-Hin-R-?model=Claude%20Opus%204.6-v1.0)

</div>
